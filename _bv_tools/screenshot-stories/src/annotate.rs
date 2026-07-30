use ab_glyph::{Font, FontVec, PxScale, ScaleFont};
use anyhow::Context;
use image::{ImageBuffer, Rgb, RgbImage};
use std::collections::HashMap;
use std::path::Path;
use std::process::Command;

fn get_git_hash() -> String {
    Command::new("git")
        .args(["rev-parse", "--short", "HEAD"])
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "unknown".to_string())
}

fn load_font() -> Option<FontVec> {
    let paths = [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNSText.ttf",
        "/Library/Fonts/Arial.ttf",
    ];
    for path in paths {
        if let Ok(data) = std::fs::read(path) {
            if let Ok(font) = FontVec::try_from_vec(data) {
                return Some(font);
            }
        }
    }
    None
}

pub fn annotate_screenshots(
    output_dir: &Path,
    id_name_map: &HashMap<String, String>,
    use_ids: bool,
) -> anyhow::Result<()> {
    let font = match load_font() {
        Some(f) => f,
        None => {
            eprintln!("\x1b[1;33mWarning: no system font found, skipping annotation\x1b[0m");
            return Ok(());
        }
    };

    let timestamp = local_datetime_str();
    let git_hash = get_git_hash();

    println!("Adding annotations to screenshots...");

    let mut png_files = Vec::new();
    collect_pngs(output_dir, &mut png_files)?;

    let total = png_files.len();
    let mut annotated = 0;
    let mut failed = 0;

    for (i, png_path) in png_files.iter().enumerate() {
        let filename = png_path.file_name().unwrap_or_default().to_string_lossy();
        println!("[{}/{}] Annotating: {}", i + 1, total, filename);

        let stem = png_path
            .file_stem()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();

        let story_name = if !id_name_map.is_empty() {
            if use_ids {
                id_name_map.get(&stem).cloned().unwrap_or(stem.clone())
            } else {
                stem.replace('-', " / ")
            }
        } else {
            stem.clone()
        };

        let line1 = story_name.clone();
        let line2 = format!("{}  |  {}", timestamp, git_hash);

        match annotate_image(png_path, &line1, &line2, &font) {
            Ok(()) => {
                println!("    \u{2713} Added: {}", line1);
                println!("           {}", line2);
                annotated += 1;
            }
            Err(e) => {
                eprintln!(
                    "\x1b[1;33m    Warning: failed to annotate {}: {}\x1b[0m",
                    filename, e
                );
                failed += 1;
            }
        }
    }

    println!("\nAnnotation Summary:");
    println!("  Annotated: {}", annotated);
    println!("  Failed: {}", failed);

    Ok(())
}

fn annotate_image(path: &Path, line1: &str, line2: &str, font: &FontVec) -> anyhow::Result<()> {
    let img = image::open(path).context("failed to open image")?.to_rgb8();
    let (width, height) = img.dimensions();
    let bar_height = 60u32;

    let mut new_img: RgbImage = ImageBuffer::new(width, height + bar_height);
    for (x, y, pixel) in img.enumerate_pixels() {
        new_img.put_pixel(x, y, *pixel);
    }
    // white bar
    for x in 0..width {
        for y in height..(height + bar_height) {
            new_img.put_pixel(x, y, Rgb([255u8, 255, 255]));
        }
    }
    // separator line
    for x in 0..width {
        new_img.put_pixel(x, height, Rgb([204u8, 204, 204]));
    }

    let scale = 14.0f32;
    let black = Rgb([0u8, 0, 0]);
    let cx = width / 2;

    draw_text_centered(
        &mut new_img,
        font,
        line1,
        cx,
        (height + 10) as i32,
        scale,
        black,
    );
    draw_text_centered(
        &mut new_img,
        font,
        line2,
        cx,
        (height + 36) as i32,
        scale,
        black,
    );

    new_img
        .save(path)
        .context("failed to save annotated image")?;
    Ok(())
}

fn text_width(font: &FontVec, text: &str, scale: PxScale) -> f32 {
    let scaled = font.as_scaled(scale);
    text.chars()
        .map(|c| scaled.h_advance(font.glyph_id(c)))
        .sum()
}

fn draw_text_centered(
    img: &mut RgbImage,
    font: &FontVec,
    text: &str,
    center_x: u32,
    top_y: i32,
    scale_px: f32,
    color: Rgb<u8>,
) {
    let px_scale = PxScale::from(scale_px);
    let w = text_width(font, text, px_scale);
    let scaled = font.as_scaled(px_scale);
    let baseline_y = top_y as f32 + scaled.ascent();
    let start_x = center_x as f32 - w / 2.0;

    let mut cursor_x = start_x;
    for ch in text.chars() {
        let glyph_id = font.glyph_id(ch);
        let glyph =
            glyph_id.with_scale_and_position(px_scale, ab_glyph::point(cursor_x, baseline_y));
        cursor_x += scaled.h_advance(glyph_id);

        if let Some(outlined) = font.outline_glyph(glyph) {
            let bounds = outlined.px_bounds();
            outlined.draw(|gx, gy, coverage| {
                let ix = bounds.min.x as i32 + gx as i32;
                let iy = bounds.min.y as i32 + gy as i32;
                if ix >= 0 && iy >= 0 {
                    let ix = ix as u32;
                    let iy = iy as u32;
                    if ix < img.width() && iy < img.height() {
                        let old = img.get_pixel(ix, iy);
                        img.put_pixel(
                            ix,
                            iy,
                            Rgb([
                                lerp(old[0], color[0], coverage),
                                lerp(old[1], color[1], coverage),
                                lerp(old[2], color[2], coverage),
                            ]),
                        );
                    }
                }
            });
        }
    }
}

fn lerp(a: u8, b: u8, t: f32) -> u8 {
    (a as f32 * (1.0 - t) + b as f32 * t) as u8
}

fn collect_pngs(dir: &Path, result: &mut Vec<std::path::PathBuf>) -> anyhow::Result<()> {
    for entry in std::fs::read_dir(dir).context("failed to read output dir")? {
        let entry = entry.context("failed to read dir entry")?;
        let path = entry.path();
        if path.is_dir() {
            collect_pngs(&path, result)?;
        } else if path.extension().and_then(|e| e.to_str()) == Some("png") {
            result.push(path);
        }
    }
    Ok(())
}

fn local_datetime_str() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let (y, mo, d, h, mi, s) = secs_to_datetime(secs);
    format!("{:04}-{:02}-{:02} {:02}:{:02}:{:02}", y, mo, d, h, mi, s)
}

fn secs_to_datetime(total_secs: u64) -> (u64, u64, u64, u64, u64, u64) {
    let h = (total_secs % 86400) / 3600;
    let mi = (total_secs % 3600) / 60;
    let s = total_secs % 60;
    let (y, mo, d) = days_to_ymd(total_secs / 86400);
    (y, mo, d, h, mi, s)
}

fn days_to_ymd(days: u64) -> (u64, u64, u64) {
    let mut d = days;
    let mut year = 1970u64;
    loop {
        let days_in_year = if is_leap(year) { 366 } else { 365 };
        if d < days_in_year {
            break;
        }
        d -= days_in_year;
        year += 1;
    }
    let months = if is_leap(year) {
        [31u64, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    } else {
        [31u64, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    };
    let mut month = 1u64;
    for &m in &months {
        if d < m {
            break;
        }
        d -= m;
        month += 1;
    }
    (year, month, d + 1)
}

fn is_leap(year: u64) -> bool {
    (year.is_multiple_of(4) && !year.is_multiple_of(100)) || year.is_multiple_of(400)
}

#[cfg(test)]
mod tests {
    use super::*;

    // is_leap

    #[test]
    fn test_leap_divisible_by_4() {
        assert!(is_leap(2024));
    }

    #[test]
    fn test_not_leap_century() {
        assert!(!is_leap(1900));
    }

    #[test]
    fn test_leap_400_year() {
        assert!(is_leap(2000));
    }

    #[test]
    fn test_not_leap_regular() {
        assert!(!is_leap(2023));
    }

    // days_to_ymd

    #[test]
    fn test_days_to_ymd_epoch() {
        assert_eq!(days_to_ymd(0), (1970, 1, 1));
    }

    #[test]
    fn test_days_to_ymd_end_of_first_year() {
        assert_eq!(days_to_ymd(364), (1970, 12, 31));
    }

    #[test]
    fn test_days_to_ymd_first_day_1971() {
        assert_eq!(days_to_ymd(365), (1971, 1, 1));
    }

    #[test]
    fn test_days_to_ymd_leap_day_2000() {
        // 2000-02-29: sum days 1970..=1999 + 31 (Jan) + 28 (Feb 1-28) + 1
        let days: u64 = (1970..2000)
            .map(|y| if is_leap(y) { 366u64 } else { 365 })
            .sum::<u64>()
            + 31
            + 28;
        assert_eq!(days_to_ymd(days), (2000, 2, 29));
    }

    #[test]
    fn test_days_to_ymd_known_date() {
        // 2024-07-10
        let days: u64 = (1970..2024)
            .map(|y| if is_leap(y) { 366u64 } else { 365 })
            .sum::<u64>()
            + 31
            + 29
            + 31
            + 30
            + 31
            + 30
            + 9; // Jan–Jun + 9 days of Jul (0-indexed)
        assert_eq!(days_to_ymd(days), (2024, 7, 10));
    }

    // secs_to_datetime

    #[test]
    fn test_secs_to_datetime_epoch() {
        assert_eq!(secs_to_datetime(0), (1970, 1, 1, 0, 0, 0));
    }

    #[test]
    fn test_secs_to_datetime_time_components() {
        let secs = 12 * 3600 + 34 * 60 + 56;
        assert_eq!(secs_to_datetime(secs), (1970, 1, 1, 12, 34, 56));
    }

    #[test]
    fn test_secs_to_datetime_midnight_next_day() {
        assert_eq!(secs_to_datetime(86400), (1970, 1, 2, 0, 0, 0));
    }
}

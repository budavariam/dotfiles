use anyhow::Context;
use serde::Deserialize;
use std::collections::HashMap;

pub struct StoryEntry {
    pub title: String,
    pub name: String,
    pub tags: Vec<String>,
}

pub struct StoriesData {
    pub entries: HashMap<String, StoryEntry>,
}

#[derive(Deserialize)]
struct RawEntry {
    title: String,
    name: String,
    #[serde(default)]
    tags: Vec<String>,
}

#[derive(Deserialize)]
struct RawStoriesData {
    entries: HashMap<String, RawEntry>,
}

pub fn fetch_stories(url: &str) -> anyhow::Result<StoriesData> {
    let index_url = format!("{}/index.json", url);
    let body: String = ureq::get(&index_url)
        .call()
        .context("failed to fetch index.json")?
        .into_string()
        .context("failed to read response body")?;

    let raw: RawStoriesData = serde_json::from_str(&body).context("failed to parse index.json")?;

    let entries = raw
        .entries
        .into_iter()
        .map(|(id, e)| {
            (
                id.clone(),
                StoryEntry {
                    title: e.title,
                    name: e.name,
                    tags: e.tags,
                },
            )
        })
        .collect();

    Ok(StoriesData { entries })
}

pub fn is_storybook_running(url: &str) -> bool {
    ureq::head(url)
        .timeout(std::time::Duration::from_secs(2))
        .call()
        .is_ok()
}

pub fn filter_stories_by_tags(
    data: &StoriesData,
    tags: &[&str],
    use_ids: bool,
) -> (Vec<String>, HashMap<String, String>) {
    let mut story_list = Vec::new();
    let mut id_name_map = HashMap::new();

    for (story_id, entry) in &data.entries {
        if entry.tags.iter().any(|t| tags.contains(&t.as_str()))
            && !entry.title.is_empty()
            && !entry.name.is_empty()
        {
            let readable_name = format!("{}/{}", entry.title, entry.name);
            id_name_map.insert(story_id.clone(), readable_name.clone());
            if use_ids {
                story_list.push(story_id.clone());
            } else {
                story_list.push(readable_name);
            }
        }
    }

    (story_list, id_name_map)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn make_test_data() -> StoriesData {
        let raw_json = json!({
            "entries": {
                "components-button--primary": {
                    "title": "Components/Button",
                    "name": "Primary",
                    "tags": ["demo", "autodocs"]
                },
                "components-button--secondary": {
                    "title": "Components/Button",
                    "name": "Secondary",
                    "tags": ["demo"]
                },
                "components-input--default": {
                    "title": "Components/Input",
                    "name": "Default",
                    "tags": ["internal"]
                }
            }
        });
        let raw: super::RawStoriesData = serde_json::from_value(raw_json).unwrap();
        let entries = raw
            .entries
            .into_iter()
            .map(|(id, e)| {
                (
                    id,
                    StoryEntry {
                        title: e.title,
                        name: e.name,
                        tags: e.tags,
                    },
                )
            })
            .collect();
        StoriesData { entries }
    }

    #[test]
    fn test_filter_by_tags_use_names() {
        let data = make_test_data();
        let (list, map) = filter_stories_by_tags(&data, &["demo"], false);
        assert_eq!(list.len(), 2);
        assert_eq!(map.len(), 2);
        assert!(list.contains(&"Components/Button/Primary".to_string()));
        assert!(list.contains(&"Components/Button/Secondary".to_string()));
        assert!(map.contains_key("components-button--primary"));
        assert!(map.contains_key("components-button--secondary"));
    }

    #[test]
    fn test_filter_by_tags_use_ids() {
        let data = make_test_data();
        let (list, map) = filter_stories_by_tags(&data, &["demo"], true);
        assert_eq!(list.len(), 2);
        assert_eq!(map.len(), 2);
        assert!(list.contains(&"components-button--primary".to_string()));
        assert!(list.contains(&"components-button--secondary".to_string()));
    }

    #[test]
    fn test_filter_no_match() {
        let data = make_test_data();
        let (list, map) = filter_stories_by_tags(&data, &["nonexistent"], false);
        assert!(list.is_empty());
        assert!(map.is_empty());
    }

    #[test]
    fn test_filter_empty_data() {
        let data = StoriesData {
            entries: HashMap::new(),
        };
        let (list, map) = filter_stories_by_tags(&data, &["demo"], false);
        assert!(list.is_empty());
        assert!(map.is_empty());
    }
}

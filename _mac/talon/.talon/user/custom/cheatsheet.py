# call it in talon REPL with: actions.user.cheatsheet()
from talon import Module, actions, registry
import sys, os
import re


def normalize_markdown(text):
    """Remove consecutive blank lines and extra spaces after headings"""
    lines = text.split("\n")
    normalized = []
    prev_blank = False

    for line in lines:
        # Check if line is blank
        is_blank = line.strip() == ""

        # Skip consecutive blank lines
        if is_blank and prev_blank:
            continue

        normalized.append(line)
        prev_blank = is_blank

    return "\n".join(normalized)


def replace_placeholders(text):
    """Replace <number>, <phrase>, etc. with $NUMBER, $PHRASE"""
    text = re.sub(r"<number(?:_\d+)?>", "$NUMBER", text)
    text = re.sub(r"<phrase(?:_\d+)?>", "$PHRASE", text)
    return text


def list_to_markdown_table(file, list_name):
    try:
        file.write(f"\n## {list_name.strip()}\n\n")
        command_list = registry.lists[list_name][0].items()
        file.write("| Command | Value |\n")
        file.write("|---------|-------|\n")
        for key, value in command_list:
            key_escaped = str(key).replace("|", "\\|")
            value_escaped = str(value).replace("|", "\\|")
            file.write(f"| **{key_escaped}** | *{value_escaped}* |\n")
        file.write("\n")
    except Exception as e:
        print(f"Failed to write list_to_markdown_table for {list_name}: {e}")


def write_alphabet(file):
    try:
        list_to_markdown_table(file, "user.letter")
    except Exception as e:
        print(f"Failed to write_alphabet: {e}")


def write_numbers(file):
    try:
        list_to_markdown_table(file, "user.number_key")
    except Exception as e:
        print(f"Failed to write_numbers: {e}")


def write_modifiers(file):
    try:
        list_to_markdown_table(file, "user.modifier_key")
    except Exception as e:
        print(f"Failed to write_modifiers: {e}")


def write_special(file):
    try:
        list_to_markdown_table(file, "user.special_key")
    except Exception as e:
        print(f"Failed to write_special: {e}")


def write_symbol(file):
    try:
        list_to_markdown_table(file, "user.symbol_key")
    except Exception as e:
        print(f"Failed to write_symbol: {e}")


def write_arrow(file):
    try:
        list_to_markdown_table(file, "user.arrow_key")
    except Exception as e:
        print(f"Failed to write_arrow: {e}")


def write_punctuation(file):
    try:
        list_to_markdown_table(file, "user.punctuation")
    except Exception as e:
        print(f"Failed to write_punctuation: {e}")


def write_function(file):
    try:
        list_to_markdown_table(file, "user.function_key")
    except Exception as e:
        print(f"Failed to write_function: {e}")


def write_formatters(file):
    try:
        file.write("\n## Formatters\n\n")
        command_list = registry.lists["user.formatters"][0].items()
        file.write("| Command | Example Output |\n")
        file.write("|---------|----------------|\n")
        for key, value in command_list:
            formatted_example = actions.user.formatted_text(
                f"example of formatting with {key}", key
            )
            key_escaped = str(key).replace("|", "\\|")
            formatted_escaped = str(formatted_example).replace("|", "\\|")
            file.write(f"| **{key_escaped}** | `{formatted_escaped}` |\n")
        file.write("\n")
    except Exception as e:
        print(f"Failed to write_formatters: {e}")


def write_context_commands(file, commands):
    try:
        for key in commands:
            try:
                rule = commands[key].rule.rule
                implementation = (
                    commands[key].script.code.replace("\n", " ").replace("\t", " ")
                )
                while "  " in implementation:
                    implementation = implementation.replace("  ", " ")

                # Replace <number> and <phrase> patterns with $NUMBER and $PHRASE
                rule = replace_placeholders(rule)
                implementation = replace_placeholders(implementation)

                implementation_escaped = implementation.replace("|", "\\|")
            except Exception:
                continue
            file.write(f"- **{rule.strip()}** `{implementation_escaped.strip()}`\n")
    except Exception as e:
        print(f"Failed to write_context_commands: {e}")


def pretty_print_context_name(file, name):
    try:
        splits = name.split(".")
        index = -1

        os_name = ""

        if "mac" in name:
            os_name = "mac"
        if "win" in name:
            os_name = "win"
        if "linux" in name:
            os_name = "linux"

        if "talon" in splits[index]:
            index = -2
            short_name = splits[index].replace("_", " ")
        else:
            short_name = splits[index].replace("_", " ")

        if "mac" == short_name or "win" == short_name or "linux" == short_name:
            index = index - 1
            short_name = splits[index].replace("_", " ")

        heading = f"{os_name} {short_name}".strip()
        file.write(f"\n## {heading}\n\n")
    except Exception as e:
        print(f"Failed to pretty_print_context_name for {name}: {e}")


mod = Module()


@mod.action_class
class user_actions:
    def cheatsheet():
        """Print out a sheet of talon commands"""
        try:
            this_dir = os.path.dirname(os.path.realpath(__file__))
            file_path = os.path.join(this_dir, "cheatsheet.md")
            temp_path = os.path.join(this_dir, "cheatsheet_temp.md")

            with open(temp_path, "w") as file:
                file.write("# Talon Voice Commands Cheatsheet\n")

                write_alphabet(file)
                write_numbers(file)
                write_modifiers(file)
                write_special(file)
                write_symbol(file)
                write_arrow(file)
                write_punctuation(file)
                write_function(file)
                write_formatters(file)

                list_of_contexts = registry.contexts.items()
                for key, value in list_of_contexts:
                    commands = value.commands
                    if len(commands) > 0:
                        pretty_print_context_name(file, key)
                        write_context_commands(file, commands)

            # Normalize markdown to remove consecutive blank lines (MD012)
            with open(temp_path, "r") as temp_file:
                content = temp_file.read()

            normalized_content = normalize_markdown(content)

            with open(file_path, "w") as final_file:
                final_file.write(normalized_content)

            # Clean up temp file
            os.remove(temp_path)

            print(f"Cheatsheet generated successfully: {file_path}")
        except Exception as e:
            print(f"Failed to generate cheatsheet: {e}")

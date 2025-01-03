use arboard::Clipboard;
use dioxus::prelude::*;
use json5;
use json_repair::repair_json_string_parallel;
use serde_json::Value;

#[component]
pub fn JsonFormat() -> Element {
    let mut input = use_signal(String::new);
    let mut output = use_signal(String::new);
    let mut show_input_search = use_signal(|| false);
    let mut show_output_search = use_signal(|| false);
    let mut input_search_query = use_signal(String::new);
    let mut output_search_query = use_signal(String::new);

    let mut format_json = move |new_input: String| {
        input.set(new_input.clone());

        // 处理空输入的情况
        if new_input.trim().is_empty() {
            output.set(String::new());
            return;
        }

        // 首先尝试使用 json5 解析
        match json5::from_str::<Value>(&new_input) {
            Ok(parsed) => {
                output.set(
                    serde_json::to_string_pretty(&parsed)
                        .unwrap_or_else(|e| format!("格式化错误: {}", e)),
                );
            }
            Err(json5_err) => {
                // 添加更详细的错误信息
                match repair_json_string_parallel(&new_input) {
                    Ok(repaired) => match serde_json::from_str::<Value>(&repaired.to_string()) {
                        Ok(parsed) => {
                            output.set(format!(
                                "// 注意：输入的 JSON 已被自动修复\n{}",
                                serde_json::to_string_pretty(&parsed)
                                    .unwrap_or_else(|e| format!("格式化错误: {}", e))
                            ));
                        }
                        Err(e) => {
                            output.set(format!(
                                "JSON 修复后仍然无法解析:\n原始错误: {}\n修复后错误: {}",
                                json5_err, e
                            ));
                        }
                    },
                    Err(e) => {
                        output.set(format!(
                            "JSON 格式错误:\n{}\n\n无法修复错误:\n{}",
                            json5_err, e
                        ));
                    }
                }
            }
        }
    };

    // 修改复制功能，移除提示信息后再复制
    let copy_output = move |_| {
        if let Ok(mut clipboard) = Clipboard::new() {
            // 获取输出内容
            let content = output.to_string();

            // 移除提示信息后的实际内容
            let clean_content = if content.starts_with("// 注意：输入的 JSON 已被自动修复\n")
            {
                content.replace("// 注意：输入的 JSON 已被自动修复\n", "")
            } else {
                content
            };

            // 设置到剪贴板
            let _ = clipboard.set_text(&clean_content);
        }
    };

    // 添加粘贴功能
    let paste_input = move |_| {
        if let Ok(mut clipboard) = Clipboard::new() {
            if let Ok(text) = clipboard.get_text() {
                format_json(text);
            }
        }
    };

    // 添加新的复制输入内容功能
    let copy_input = move |_| {
        if let Ok(mut clipboard) = Clipboard::new() {
            let _ = clipboard.set_text(&input.to_string());
        }
    };

    rsx! {
        div {
            style: "display: flex; flex-direction: column; gap: 20px; height: 100%;",
            div {
                style: "display: flex; gap: 20px; flex: 1;",
                div {
                    style: "flex: 1; display: flex; flex-direction: column; padding-right: 10px;",
                    // 输入框上方的按钮组
                    div {
                        style: "display: flex; justify-content: flex-end; gap: 10px; margin-bottom: 10px;",
                        button {
                            onclick: paste_input,
                            title: "从剪贴板粘贴",
                            img {
                                src: "assets/icons/paste.svg",
                                alt: "paste",
                                style: "width: 16px; height: 16px;"
                            }
                        }
                        button {
                            onclick: copy_input,
                            title: "复制到剪贴板",
                            img {
                                src: "assets/icons/copy.svg",
                                alt: "copy",
                                style: "width: 16px; height: 16px;"
                            }
                        }
                        button {
                            onclick: move |_| format_json(String::new()),
                            title: "清空",
                            img {
                                src: "assets/icons/clear.svg",
                                alt: "clear",
                                style: "width: 16px; height: 16px;"
                            }
                        }
                        button {
                            onclick: move |_| show_input_search.set(true),
                            title: "搜索",
                            img {
                                src: "assets/icons/search.svg",
                                alt: "search",
                                style: "width: 16px; height: 16px;"
                            }
                        }
                    }

                    // 输入区搜索框
                    if show_input_search() {
                        div {
                            style: "display: flex; gap: 10px; align-items: center; height: 32px; border: 1px solid #ddd; border-radius: 4px; padding: 0 10px; background: white; width: 100%; margin-bottom: 2px;",
                            img {
                                src: "assets/icons/search.svg",
                                alt: "search",
                                style: "width: 14px; height: 14px; min-width: 14px;"
                            }
                            input {
                                style: "flex: 1; border: none; padding: 0 8px; outline: none; width: 100%;",
                                placeholder: "搜索",
                                value: "{input_search_query}",
                                autocomplete: "off",
                                spellcheck: "false",
                                autofocus: true,
                                oninput: move |evt| input_search_query.set(evt.data.value())
                            }
                            button {
                                style: "display: flex; align-items: center; justify-content: center; min-width: 14px;",
                                onclick: move |_| {
                                    show_input_search.set(false);
                                    input_search_query.set(String::new());
                                },
                                title: "关闭",
                                img {
                                    src: "assets/icons/close.svg",
                                    alt: "close",
                                    style: "width: 14px; height: 14px;"
                                }
                            }
                        }
                    }

                    textarea {
                        style: {
                            let base_style = "flex: 1; width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; resize: none; outline: none;";
                            if show_input_search() {
                                format!("{} height: calc(100% - 42px);", base_style)
                            } else {
                                format!("{} height: 100%;", base_style)
                            }
                        },
                        value: "{input}",
                        autocomplete: "off",
                        spellcheck: "false",
                        autofocus: true,
                        placeholder: "请输入要格式化的 JSON...",
                        oninput: move |evt| format_json(evt.data.value()),
                    }
                }
                div {
                    style: "flex: 1; display: flex; flex-direction: column; padding-right: 10px;",
                    // 输出框上方的按钮组
                    div {
                        style: "display: flex; justify-content: flex-end; gap: 10px; margin-bottom: 10px;",
                        button {
                            onclick: copy_output,
                            title: "复制到剪贴板",
                            img {
                                src: "assets/icons/copy.svg",
                                alt: "copy",
                                style: "width: 16px; height: 16px;"
                            }
                        }
                        button {
                            onclick: move |_| show_output_search.set(true),
                            title: "搜索",
                            img {
                                src: "assets/icons/search.svg",
                                alt: "search",
                                style: "width: 16px; height: 16px;"
                            }
                        }
                    }

                    // 输出区搜索框
                    if show_output_search() {
                        div {
                            style: "display: flex; gap: 10px; align-items: center; height: 32px; border: 1px solid #ddd; border-radius: 4px; padding: 0 10px; background: white; width: 100%; margin-bottom: 2px;",
                            img {
                                src: "assets/icons/search.svg",
                                alt: "search",
                                style: "width: 14px; height: 14px; min-width: 14px;"
                            }
                            input {
                                style: "flex: 1; border: none; padding: 0 8px; outline: none; width: 100%;",
                                placeholder: "搜索",
                                value: "{output_search_query}",
                                autocomplete: "off",
                                spellcheck: "false",
                                autofocus: true,
                                oninput: move |evt| output_search_query.set(evt.data.value())
                            }
                            button {
                                style: "display: flex; align-items: center; justify-content: center; min-width: 14px;",
                                onclick: move |_| {
                                    show_output_search.set(false);
                                    output_search_query.set(String::new());
                                },
                                title: "关闭",
                                img {
                                    src: "assets/icons/close.svg",
                                    alt: "close",
                                    style: "width: 14px; height: 14px;"
                                }
                            }
                        }
                    }

                    textarea {
                        style: {
                            let base_style = "flex: 1; width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; resize: none; outline: none;";
                            if show_output_search() {
                                format!("{} height: calc(100% - 42px);", base_style)
                            } else {
                                format!("{} height: 100%;", base_style)
                            }
                        },
                        readonly: true,
                        placeholder: "格式化结果将在这里显示...",
                        value: "{output}"
                    }
                }
            }
        }
    }
}

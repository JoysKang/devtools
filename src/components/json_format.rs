use dioxus::prelude::*;
use json5;
use json_repair::repair_json_string_parallel;
use serde_json::Value;
use arboard::Clipboard;

#[component]
pub fn JsonFormat() -> Element {
    let mut input = use_signal(String::new);
    let mut output = use_signal(String::new);

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
                output.set(serde_json::to_string_pretty(&parsed)
                    .unwrap_or_else(|e| format!("格式化错误: {}", e)));
            }
            Err(json5_err) => {
                // 添加更详细的错误信息
                match repair_json_string_parallel(&new_input) {
                    Ok(repaired) => {
                        match serde_json::from_str::<Value>(&repaired.to_string()) {
                            Ok(parsed) => {
                                output.set(format!(
                                    "// 注意：输入的 JSON 已被自动修复\n{}",
                                    serde_json::to_string_pretty(&parsed)
                                        .unwrap_or_else(|e| format!("格式化错误: {}", e))
                                ));
                            }
                            Err(e) => {
                                output.set(format!("JSON 修复后仍然无法解析:\n原始错误: {}\n修复后错误: {}", json5_err, e));
                            }
                        }
                    }
                    Err(e) => {
                        output.set(format!("JSON 格式错误:\n{}\n\n无法修复错误:\n{}", json5_err, e));
                    }
                }
            }
        }
    };

    // 修复复制功能
    let copy_output = move |_| {
        if let Ok(mut clipboard) = Clipboard::new() {
            let _ = clipboard.set_text(&output.to_string());
        }
    };

    rsx! {
        div {
            style: "display: flex; flex-direction: column; gap: 20px; height: 100%;",
            div {
                style: "display: flex; gap: 20px; flex: 1;",
                textarea {
                    autocomplete: "off",
                    style: "flex: 1; padding: 10px; border: 1px solid #ccc; border-radius: 4px; resize: none; font-size: 16px; font-family: monospace;",
                    placeholder: "请输入要格式化的 JSON...",
                    value: "{input}",
                    oninput: move |evt| format_json(evt.data.value())
                }
                div {
                    style: "flex: 1; display: flex; flex-direction: column;",
                    div {
                        style: "display: flex; justify-content: space-between; margin-bottom: 10px;",
                        button {
                            onclick: copy_output,
                            "复制结果"
                        }
                    }
                    textarea {
                        style: "flex: 1; padding: 10px; border: 1px solid #ccc; border-radius: 4px; resize: none; font-size: 16px; font-family: monospace;",
                        readonly: true,
                        placeholder: "格式化结果将在这里显示...",
                        value: "{output}"
                    }
                }
            }
        }
    }
}
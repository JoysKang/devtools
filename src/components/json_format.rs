use dioxus::prelude::*;
use json5;
use json_repair::repair_json_string_parallel;
use serde_json::Value;

#[component]
pub fn JsonFormat() -> Element {
    // 创建输入文本的状态
    let mut input = use_signal(String::new);
    // 创建输出文本的状态
    let mut output = use_signal(String::new);

    // 处理 JSON 格式化的函数
    let mut format_json = move |new_input: String| {
        // 更新输入状态
        input.set(new_input.clone());
        
        // 首先尝试使用 json5 解析
        match json5::from_str::<Value>(&new_input) {
            Ok(parsed) => {
                // 格式化成功，美化输出
                output.set(serde_json::to_string_pretty(&parsed).unwrap_or_default());
            }
            Err(_) => {
                // json5 解析失败，尝试使用 json-repair 修复
                match repair_json_string_parallel(&new_input) {
                    Ok(repaired) => {
                        // 修复成功，再次尝试解析和美化
                        match serde_json::from_str::<Value>(&repaired.to_string()) {
                            Ok(parsed) => {
                                output.set(serde_json::to_string_pretty(&parsed).unwrap_or_default());
                            }
                            Err(e) => {
                                output.set(format!("JSON 修复后仍然无法解析: {}", e));
                            }
                        }
                    }
                    Err(e) => {
                        output.set(format!("JSON 修复失败: {}", e));
                    }
                }
            }
        }
    };

    rsx! {
        div {
            style: "display: flex; gap: 20px; height: 100%;",
            textarea {
                style: "flex: 1; padding: 10px; border: 1px solid #ccc; border-radius: 4px; resize: none; font-size: 16px; font-family: monospace;",
                placeholder: "请输入要格式化的 JSON...",
                value: "{input}",
                oninput: move |evt| format_json(evt.data.value())
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
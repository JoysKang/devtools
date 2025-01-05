// use flutter_rust_bridge::frb;
// use serde_json::Value;
// use json_repair;

// #[frb(sync)]
// pub fn format_json(input: String) -> String {
//     let new_input = input.trim();
    
//     // 首先尝试使用 json5 解析（更宽松的 JSON 解析）
//     match json5::from_str::<Value>(&new_input) {
//         Ok(parsed) => {
//             // JSON5 解析成功，返回格式化的 JSON
//             serde_json::to_string_pretty(&parsed)
//                 .unwrap_or_else(|e| format!("格式化错误: {}", e))
//         }
//         Err(json5_err) => {
//             // JSON5 解析失败，尝试修复
//             // match json_repair::repair_json_string_parallel(&new_input) {
//             //     Ok(repaired) => {
//             //         // 尝试解析修复后的 JSON
//             //         match serde_json::from_str::<Value>(&repaired) {
//             //             Ok(parsed) => {
//             //                 format!(
//             //                     "// 注意：输入的 JSON 已被自动修复\n{}",
//             //                     serde_json::to_string_pretty(&parsed)
//             //                         .unwrap_or_else(|e| format!("格式化错误: {}", e))
//             //                 )
//             //             }
//             //             Err(e) => {
//             //                 format!("JSON 修复后仍然无法解析:\n原始错误: {}\n修复后错误: {}", json5_err, e)
//             //             }
//             //         }
//             //     }
//             //     Err(e) => {
//             //         format!("JSON 格式错误:\n{}\n\n无法修复错误:\n{}", json5_err, e)
//             //     }
//             // }
//         }
//     }
// }

// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn test_format_valid_json() {
//         let input = r#"{"name":"张三","age":25}"#;
//         let result = format_json(input.to_string());
//         assert!(result.contains("张三"));
//         assert!(result.contains("25"));
//     }

//     #[test]
//     fn test_format_invalid_json() {
//         let input = r#"{"name":"张三",age:25}"#; // 缺少 age 的引号
//         let result = format_json(input.to_string());
//         assert!(result.contains("已被自动修复"));
//     }
// }


pub fn greet2(name: String) -> String {
    format!("Hello, {name}!")
}

// #[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

use serde_json::Value;
use json5;
use json_repair;


pub fn format_json(input: String) -> String {
    let new_input = input.trim();
    
    // 第一步：尝试使用 json5 解析（json5 比标准 JSON 更宽松）
    match json5::from_str::<Value>(&new_input) {
        Ok(parsed) => {
            // JSON5 解析成功，直接格式化返回
            serde_json::to_string_pretty(&parsed)
                .unwrap_or_else(|e| format!("格式化错误: {}", e))
        }
        Err(json5_err) => {
            // 第二步：如果 JSON5 解析失败，尝试修复
            match json_repair::repair_json_string_parallel(&new_input) {
                Ok(repaired) => {
                    // 第三步：尝试解析修复后的 JSON
                    match serde_json::from_str::<Value>(&repaired.to_string()) {
                        Ok(parsed) => {
                            // 修复成功并且可以解析
                            format!(
                                "// 注意：输入的 JSON 已被自动修复\n{}",
                                serde_json::to_string_pretty(&parsed)
                                    .unwrap_or_else(|e| format!("格式化错误: {}", e))
                            )
                        }
                        Err(e) => {
                            // 修复后仍然无法解析
                            format!("JSON 修复后仍然无法解析:\n原始错误: {}\n修复后错误: {}", json5_err, e)
                        }
                    }
                }
                Err(e) => {
                    // 无法修复
                    format!("JSON 格式错误:\n{}\n\n无法修复错误:\n{}", json5_err, e)
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_json() {
        let input = r#"{"name": "张三", "age": 25}"#;
        let result = format_json(input.to_string());
        assert!(result.contains("张三"));
        assert!(result.contains("25"));
        assert!(!result.contains("已被自动修复"));
    }

    #[test]
    fn test_json5_format() {
        let input = r#"{
            name: "张三",  // 没有引号的键
            age: 25,      // 尾随逗号
        }"#;
        let result = format_json(input.to_string());
        assert!(result.contains("张三"));
        assert!(result.contains("25"));
    }

    #[test]
    fn test_invalid_json() {
        let input = r#"{name: 张三, age: 25]"#;  // 严重错误的 JSON
        let result = format_json(input.to_string());
        assert!(result.contains("错误"));
    }
}

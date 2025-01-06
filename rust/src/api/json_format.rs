use serde::Serialize;
use serde_json::{Value, ser::PrettyFormatter};
use json5;
use json_repair;

/// JSON 缩进类型
#[derive(Debug)]
pub enum IndentType {
    Spaces2,  // 2个空格缩进
    Spaces4,  // 4个空格缩进
    Tab,      // Tab缩进
    None,     // 压缩模式，无缩进
}

/// 格式化 JSON 字符串
/// 
/// # 参数
/// * `input` - 输入的 JSON 字符串
/// * `indent_type` - 缩进类型
/// 
/// # 返回
/// * 格式化后的 JSON 字符串，或错误信息
pub fn format_json(input: String, indent_type: IndentType) -> String {
    let input = input.trim();
    
    // 解析流程：
    // 1. 尝试用 JSON5 解析（支持注释、尾随逗号等）
    // 2. 如果失败，尝试修复并重新解析
    // 3. 最后进行格式化输出
    let parse_result = json5::from_str::<Value>(input)
        .or_else(|json5_err| {
            // 尝试修复并解析
            json_repair::repair_json_string_parallel(input)
                .map_err(|e| format!("{}", e))  // 转换修复错误为字符串
                .and_then(|repaired| serde_json::from_str(&repaired.to_string())  // 解析修复后的JSON
                    .map_err(|e| format!("{}", e)))  // 转换解析错误为字符串
                .map(|parsed| parsed)  // 返回解析成功的值
                .map_err(|repair_err| format!(  // 合并错误信息
                    "JSON 格式错误:\n{}\n修复失败: {}", 
                    json5_err, repair_err
                ))
        });

    match parse_result {
        Ok(parsed) => format_value(&parsed, &indent_type),
        Err(err) => err,
    }
}

/// 根据指定的缩进格式化 JSON 值
/// 
/// # 参数
/// * `value` - 要格式化的 JSON 值
/// * `indent_type` - 缩进类型
/// 
/// # 返回
/// * 格式化后的 JSON 字符串
fn format_value(value: &Value, indent_type: &IndentType) -> String {
    match indent_type {
        IndentType::None => {
            // 压缩模式：移除所有不必要的空白字符
            serde_json::to_string(value)
                .unwrap_or_else(|e| format!("格式化错误: {}", e))
        }
        _ => {
            // 根据缩进类型创建格式化器
            let formatter = match indent_type {
                IndentType::Spaces2 => PrettyFormatter::with_indent(b"  "),
                IndentType::Spaces4 => PrettyFormatter::with_indent(b"    "),
                IndentType::Tab => PrettyFormatter::with_indent(b"\t"),
                IndentType::None => unreachable!(),
            };
            
            // 使用指定的格式化器序列化 JSON
            let buf = Vec::new();
            let mut ser = serde_json::Serializer::with_formatter(buf, formatter);
            match value.serialize(&mut ser) {
                Ok(_) => String::from_utf8(ser.into_inner())
                    .unwrap_or_else(|e| format!("UTF-8 编码错误: {}", e)),
                Err(e) => format!("序列化错误: {}", e),
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_indentation() {
        let input = r#"{"name":"张三","age":25}"#;
        
        // 测试不同的缩进格式
        assert!(format_json(input.into(), IndentType::Spaces2).contains("  \"name\""));
        assert!(format_json(input.into(), IndentType::Spaces4).contains("    \"name\""));
        assert!(format_json(input.into(), IndentType::Tab).contains("\t\"name\""));
        assert!(!format_json(input.into(), IndentType::None).contains("\n"));
    }

    #[test]
    fn test_json5_features() {
        // 测试 JSON5 特性（注释、无引号键名、尾随逗号）
        let input = r#"{
            // 注释
            name: "张三",
            age: 25,
        }"#;
        let result = format_json(input.into(), IndentType::Spaces2);
        assert!(result.contains("\"name\""));
        assert!(result.contains("\"张三\""));
    }

    #[test]
    fn test_error_handling() {
        // 测试错误处理
        let invalid_input = r#"{name: 无效的值}"#;
        let result = format_json(invalid_input.into(), IndentType::Spaces2);
        assert!(result.contains("错误"));
    }
}

use better_json::{parse, CrateDefault, ParseOptions};
use serde_json::Value;

fn repair_json(broken_json: &str) -> Result<String, Box<dyn std::error::Error>> {
    // 配置解析选项，使其更宽容地处理错误的JSON
    let options = ParseOptions {
        allow_comments: true,
        allow_trailing_commas: true,
        allow_loose_escapes: true,
        ..CrateDefault::default()
    };

    // 尝试解析并修复JSON
    let repaired_value = parse(broken_json, Some(&options))?;
    
    // 将修复后的值转换回JSON字符串
    let repaired_json = serde_json::to_string_pretty(&repaired_value)?;
    Ok(repaired_json)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 一些常见的损坏JSON示例
    let broken_examples = vec![
        // 缺少引号的键
        r#"{name: "John", age: 30}"#,
        
        // 多余的逗号
        r#"{
            "name": "John",
            "age": 30,
            "city": "New York",, 
        }"#,
        
        // 注释（标准JSON不支持）
        r#"{
            // User info
            "name": "John",
            "age": 30 /* current age */
        }"#,
        
        // 错误的引号使用
        r#"{
            'name': "John",
            "age": 30
        }"#
    ];

    for (i, broken_json) in broken_examples.iter().enumerate() {
        println!("\nExample {}:\nBroken JSON: {}", i + 1, broken_json);
        match repair_json(broken_json) {
            Ok(fixed) => println!("Fixed JSON: {}", fixed),
            Err(e) => println!("Error fixing JSON: {}", e),
        }
    }

    Ok(())
}
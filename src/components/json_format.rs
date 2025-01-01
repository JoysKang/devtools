use dioxus::prelude::*;

#[component]
pub fn JsonFormat() -> Element {
    rsx! {
        div {
            style: "display: flex; gap: 20px; height: 100%;",
            textarea {
                style: "flex: 1; padding: 10px; border: 1px solid #ccc; border-radius: 4px; resize: none;",
                placeholder: "请输入要格式化的 JSON..."
            }
            textarea {
                style: "flex: 1; padding: 10px; border: 1px solid #ccc; border-radius: 4px; resize: none;",
                readonly: true,
                placeholder: "格式化结果将在这里显示..."
            }
        }
    }
} 
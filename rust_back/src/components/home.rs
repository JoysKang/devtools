use dioxus::prelude::*;

#[component]
pub fn Home() -> Element {
    rsx! {
        h2 { "欢迎使用 devtools" }
    }
} 
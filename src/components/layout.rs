use dioxus::prelude::*;
use dioxus_router::prelude::*;
use crate::routes::Route;

#[component]
pub fn Layout() -> Element {
    rsx! {
        div {
            style: "display: flex; height: 100vh; width: 100%;",
            
            nav {
                style: "width: 100px; background-color: #f0f0f0; padding: 15px;",
                ul {
                    style: "list-style: none; padding: 0;",
                    li {
                        style: "cursor: pointer; padding: 8px 0;",
                        Link { to: Route::Home, "首页" }
                    }
                    li {
                        style: "cursor: pointer; padding: 8px 0;",
                        Link { to: Route::JsonFormat, "JSON格式化" }
                    }
                    li {
                        style: "cursor: pointer; padding: 8px 0;",
                        Link { to: Route::Timestamp, "时间戳转换" }
                    }
                }
            }

            main {
                style: "flex: 1; padding: 20px;",
                Outlet::<Route> {}
            }
        }
    }
}
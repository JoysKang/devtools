use dioxus::prelude::*;
use dioxus_router::prelude::*;
use crate::components::*;

#[derive(Clone, Routable)]
pub enum Route {
    #[layout(Layout)]
    #[route("/")]
    Home,
    #[route("/json")]
    JsonFormat,
    #[route("/timestamp")]
    Timestamp,
} 
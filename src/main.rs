mod routes;
mod components;

use dioxus::prelude::*;
use dioxus_router::prelude::*;
use routes::Route;

fn main() {
    launch(App);
}

#[component]
fn App() -> Element {
    rsx! {
        Router::<Route> {}
    }
}

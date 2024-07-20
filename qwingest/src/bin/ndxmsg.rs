use dotenv::dotenv;
use std::env;
use std::fs::File;
use std::io::Write;

use mongodb::{
    bson::doc,
    options::FindOptions,
    sync::{Client, Collection},
};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct User {
    username: Option<String>,
    name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct Files {
    name: Option<String>,
    #[serde(rename = "type")]
    _type: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct Message {
    rid: String,
    msg: String,
    u: Option<User>,
    files: Option<Vec<Files>>,
}

struct MsgManager {
    msgcol: Collection<Message>,
}

impl MsgManager {
    fn init() -> Self {
        dotenv().ok();
        let uri = match env::var("MONGOURI") {
            Ok(v) => v.to_string(),
            Err(_) => "Error loading env variable".to_owned(),
        };
        let client = Client::with_uri_str(uri).unwrap();
        let db = client.database("rocketchat");
        let msgcol: Collection<Message> = db.collection("rocketchat_message");
        MsgManager { msgcol }
    }

    fn get_messages(&self, numbr: i64, fpath: &str) {
        let filter = doc! { "u.username": { "$not": {"$regex": "^zabbix.*"} }, "msg": { "$exists": true } };
        let find_options = FindOptions::builder().limit(numbr).build();
        let cursors = self
            .msgcol
            .find(filter, find_options)
            .expect("Error getting list of docs");
        let mut fl = File::create(fpath).expect("cannot create file");
        for result in cursors {
            let doc = result.expect("no messages");
            let mut s: String = serde_json::to_string(&doc).unwrap();
            s += "\n";
            fl.write_all(s.as_bytes()).expect("cannot write to file");
        }
    }
}

fn main() {
    let ops: Vec<String> = std::env::args().collect();
    let operation = ops[1].as_str();
    let param: i64 = ops[2]
        .as_str()
        .parse()
        .expect("cannot convert string to number");
    let file_path = ops[3].as_str();
    let mm = MsgManager::init();
    println!("Successfully connected to mongodb");

    match operation {
        "get" => mm.get_messages(param, file_path),
        _ => panic!("invalid operation specified"),
    }
}

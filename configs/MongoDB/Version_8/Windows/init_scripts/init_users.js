// Admin user
db = db.getSiblingDB("admin");
if (!db.getUser("admin")) {
  db.createUser({
    user: "admin",
    pwd: "ChangeMe_StrongPassword!",
    roles: [ { role: "root", db: "admin" } ]
  });
  print("Admin user 'admin' created.");
} else {
  print("Admin user 'admin' already exists.");
}

// Only initialize the explicitly selected, new localhost bootstrap instance.
if (process.env.MONGO_BOOTSTRAP !== "1" || !process.env.MONGO_BOOTSTRAP_DBPATH) {
  throw new Error("Explicit bootstrap required. Use init_mongodb.bat --bootstrap as described in the README.");
}
const admin = db.getSiblingDB("admin");
const options = admin.adminCommand({ getCmdLineOpts: 1 }).parsed;
const normalizePath = (path) => {
  const value = String(path || "").replace(/\\/g, "/").replace(/\/+$/, "");
  return process.platform === "win32" ? value.toLowerCase() : value;
};
if (normalizePath(options.storage?.dbPath) !== normalizePath(process.env.MONGO_BOOTSTRAP_DBPATH)) {
  throw new Error("Refusing bootstrap: the server uses a different data directory.");
}
const addresses = String(options.net?.bindIp || "").split(",").map((ip) => ip.trim());
if (options.net?.bindIpAll || !addresses.length || addresses.some((ip) => !["127.0.0.1", "::1"].includes(ip))) {
  throw new Error("Refusing bootstrap: the server must bind exclusively to loopback addresses.");
}
if (options.security?.authorization === "enabled") {
  throw new Error("Refusing bootstrap: the dedicated server must use --noauth.");
}
if (admin.getUsers().users.length !== 0) {
  throw new Error("Refusing bootstrap: administrator users already exist.");
}
print("Enter a new password for the admin account:");
const password = passwordPrompt();
print("Repeat the new password:");
if (!password || password !== passwordPrompt()) {
  throw new Error("Passwords must be nonempty and match.");
}
admin.createUser({ user: "admin", pwd: password, roles: [{ role: "root", db: "admin" }] });
print("Admin created. Stop this bootstrap server before starting the TLS configuration.");

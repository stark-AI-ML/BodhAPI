import { Pool } from "pg";

const pool = new Pool({
  user: "postgres",
  host: "localhost",
  database: "news",
  password: "#Postgress_3000",
  port: 5432,
});
export default pool;

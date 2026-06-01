import e, { Router } from "express";

import service from "./bussiness.service.js";

const formatter = require("./business.formatter");

exports.getTodayNews = async (req, res) => {
  const data = await service.fetchTodayNews(40);
  
  const formatted = formatter.formatPositive(data);
  res.status(200).json(formatted);
};

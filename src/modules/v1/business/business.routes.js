import express from "express";
import * as controller from "./business.controller.js";

const router = express.Router();

router.get("/business/v1/today", controller.getTodayNews);

router.get("/business/v1/top", controller.getTopNews);

router.get("/business/v1/tech", controller.getTechNews);

router.get("/business/v1/finance", controller.getFinanceNews);

router.get("/business/v1/sentiment", controller.getSentimentNews);

router.get("/business/v1/state", controller.getStateNews);

export default router;

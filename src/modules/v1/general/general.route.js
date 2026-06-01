import express from "express";
import * as controller from "./general.controller.js";

const router = express.Router();

router.get("/general/v1/today", controller.getTodayNews);

router.get("/general/v1/top", controller.getTopNews);

router.get("/general/v1/crime", controller.getCrimeNews);

router.get("/general/v1/sentiment", controller.getSentimentNews);

router.get("/general/v1/state", controller.getStateNews);

router.get("/general/v1/entities", controller.getEntitiesNews);

export default router;

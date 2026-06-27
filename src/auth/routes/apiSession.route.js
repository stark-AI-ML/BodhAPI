import {
  getCurrentKeys,
  deleteApiKey,
} from '../controllers/apiKey.controller.js';

// i think this folder is over kill fuck perfectionism -------fallow yagni
// but maybe in analytics later it can help

import e from 'express';

const router = e.Router();

router.get('/getCurrentKeys', getCurrentKeys);
router.delete('/removeKey', deleteApiKey);

export default router;

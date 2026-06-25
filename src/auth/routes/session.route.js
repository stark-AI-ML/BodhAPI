import e from 'express';

import * as controller from '../../auth/controllers/session.controller.js';

const router = e.Router();

router.post('/login', controller.login);

router.post('/refresh', controller.refresh);

router.post('/logout', controller.logout);

export default router;

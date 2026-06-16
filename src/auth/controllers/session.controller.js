import * as authService from '../services/auth.service.js';

export const createSession = async (user, metadata) => {
  // const { user } = req; // assume validated

  console.log('under the createSEssion');

  const { accessToken, refreshToken } = await authService.login(
    user,
    metadata.ip,
    metadata.userAgent
  );

  return { accessToken, refreshToken };
};

// /test-debug --> during this test i found that user refresh token must have uuid which is good,

// but you must update the email or check for exisisting : thing as original email was rslikefoot00@gmail.com
// but token  still assigned  ---- update that in service layer

// see the only problem is you are able to create new user with same (user_id )and google_id
// --- so in service layer check with google_id or user_id exsistence before creating user

//---- although i don't think it matter you fuck you are doing it when user_id check was already happend so
// so you as a developer has this hack user will not have it

// /test-debug
// ----------------------------------------------------------------------
// const user = {
//   user_id: '2cfef765-be93-4f01-b96f-88f2b2b2ec39',
//   google_id: '102986733135526075622',
//   email: 'rs@123',
//   picture: 'user.picture',
//   display_name: ' user.display_name',
//   plan: 3,
// };

// const metadata = {
//   ip: '192.30.0.0/16',
//   userAgent: 'mozilla',
// };

// const data = await createSession(user, metadata);

// console.log(data);
//--------------------------------------------------------------------------

export const refresh = async (req, res, next) => {
  try {
    const token = req.cookies.refreshToken;

    if (!token) return res.sendStatus(401);

    const { newAccessToken, newRefreshToken } = await authService.refresh(
      token,
      req.ip,
      req.headers

      // req.headers['user-agent']
    );

    // res.cookie('refreshToken', newRefreshToken, {
    //   httpOnly: true,

    //   secure: true,
    //   sameSite: 'Strict',
    // });

    // for localhost :

    console.log('got newAccessToken :  ', newAccessToken);

    res.cookie('refreshToken', newRefreshToken, {
      httpOnly: true,
      secure: true,
      sameSite: 'none',
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    });

    return res.json({ accessToken: newAccessToken });

    next();
  } catch (err) {
    return res.sendStatus(403);
  }
};

//-------------------------------------------------------------------------------------------------------------

// const req = {
//   cookies:
//     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjBiMTVmODExLTJmMWYtNDZhMy05MzI5LTE4MTdiNzhkNTdkMCIsImlhdCI6MTc4MTQyMTkxNywiZXhwIjoxNzgyMDI2NzE3fQ.Ia73sWL2YybvMddcpvABz7mxoI_Y5pIfItMLztRursk',
//   ip: '192.30.0.0/16',
//   headers: 'mozilla',
// };

// refresh()
//---------------------------------------------------------------------------------------------------------------------------------
export const logout = async (req, res) => {
  try {
    const token = req.cookies.refreshToken;
    if (token) {
      await authService.logout(token);
    }
    res.clearCookie('accessToken');
    res.clearCookie('refreshToken');
    res.sendStatus(204);
  } catch {
    res.sendStatus(500);
  }
};

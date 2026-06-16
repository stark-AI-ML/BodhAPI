import validator from 'validator'; // won't recommend using it too much

// see my mistake was, i was sending req.body instead of req (which is right in real)
// but needed a fix like its a json so we need to accept and des

export const validateEntry = (body = {}) => {
  const { name, email, googleKey } = body;

  //    if(!email || !name || !gender || !age){
  //     throw new Error("missing field")
  //    }

  const missing = Object.entries({ email, name, googleKey })
    .filter(([_, value]) => !value)
    .map(([key]) => key);

  if (missing.length) {
    throw new Error(`missing these fields ${missing.join(', ')}`);
  }
  // validating email with validator module i can right my own but later also they use regex which i don't want to now enough

  if (!validator.isEmail(email)) {
    throw new Error('Invalid Email id');
  }
};

export const validateEmail = (email) => {
  if (!validator.isEmail(email)) {
    throw new Error('Invalid EmailId');
  }
};

export const getTTL = (fx_Name, data_type) => {
  switch (fx_Name) {
    case 'acessToken':
      if (data_type == 'string') return '1d'; // /fix if you will get better ram :) but for prod it's good
      if (data_type == 'integer') return 24 * 60 * 60 * 1000;
      break;
    case 'refreshToken':
      if (data_type == 'string') return '30d';
      if (data_type == 'integer') return 30 * 24 * 60 * 60 * 1000;
      break;
    default:
      if (data_type == 'string') return '30d';
      if (data_type == 'integer') return 30 * 24 * 60 * 60 * 1000;
  }
};

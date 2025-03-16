import { AppBar, Toolbar, Typography } from '@mui/material';
import { CONFIG } from '@/constants/config';

export default function Header() {
  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6">{CONFIG.APP_NAME}</Typography>
      </Toolbar>
    </AppBar>
  );
} 
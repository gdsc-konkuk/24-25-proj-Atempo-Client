'use client'

import { AppBar, Toolbar, Button, Box, Container } from '@mui/material';

export default function Navbar() {
  return (
    <AppBar position="static" color="transparent" elevation={0}>
      <Container maxWidth="lg">
        <Toolbar sx={{ justifyContent: 'center' }}>
          <Box sx={{ display: 'flex', gap: 3 }}>
            <Button color="inherit">학습</Button>
            <Button color="inherit">게시판</Button>
            <Button color="inherit">프로필</Button>
            <Button color="inherit">설정</Button>
          </Box>
        </Toolbar>
      </Container>
    </AppBar>
  );
} 
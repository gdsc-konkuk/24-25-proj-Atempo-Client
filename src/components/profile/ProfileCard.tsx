'use client'

import { Card, CardContent, Typography, Box, LinearProgress } from '@mui/material';
import Image from 'next/image';

export default function ProfileCard() {
  return (
    <Card sx={{ mb: 4 }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
          <Image
            src="https://placehold.co/80x80"
            alt="Profile"
            width={80}
            height={80}
            style={{ borderRadius: '50%' }}
          />
          <Box sx={{ ml: 2 }}>
            <Typography variant="h6">지디지님 Lv 5</Typography>
            <Typography variant="body2" color="text.secondary">
              gdsc-konkuk@gmail.com
            </Typography>
          </Box>
        </Box>
        <Box sx={{ mt: 2 }}>
          <Typography variant="body2" color="text.secondary">
            다음 레벨까지 40 EXP 남았습니다
          </Typography>
          <LinearProgress 
            variant="determinate" 
            value={60} 
            sx={{ 
              mt: 1,
              height: 8,
              borderRadius: 4,
              bgcolor: '#f0f0f0',
              '& .MuiLinearProgress-bar': {
                bgcolor: '#FF66C0'
              }
            }} 
          />
        </Box>
      </CardContent>
    </Card>
  );
} 
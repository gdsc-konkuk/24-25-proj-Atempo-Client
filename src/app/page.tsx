'use client'

import { Container, Grid } from '@mui/material';
import Navbar from '@/components/layout/Navbar';
import ProfileCard from '@/components/profile/ProfileCard';
import RecentPosts from '@/components/posts/RecentPosts';
import RecommendedThemes from '@/components/themes/RecommendedThemes';
import RecentLearning from '@/components/learning/RecentLearning';

export default function HomePage() {
  return (
    <>
      <Navbar />
      <Container maxWidth="lg" sx={{ mt: 4 }}>
        <Grid container spacing={4}>
          <Grid item xs={12} md={4}>
            <ProfileCard />
            <RecentPosts />
          </Grid>
          <Grid item xs={12} md={8}>
            <RecentLearning />
            <RecommendedThemes />
          </Grid>
        </Grid>
      </Container>
    </>
  );
} 
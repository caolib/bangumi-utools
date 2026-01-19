<script setup>
import { onMounted, ref, computed, watch } from 'vue';
import HomeView from './components/HomeView.vue';
import { useSettingsStore } from './stores/settings';

const enterAction = ref({});
const settingsStore = useSettingsStore();
const systemDarkMode = ref(window.matchMedia('(prefers-color-scheme: dark)').matches);

const actualTheme = computed(() => {
  // theme is a computed ref from the store
  const t = settingsStore.theme.value;
  if (t === 'system') {
    return systemDarkMode.value ? 'dark' : 'light';
  }
  return t;
});

watch(actualTheme, (newTheme) => {
  document.documentElement.setAttribute('data-theme', newTheme);
}, { immediate: true });

onMounted(() => {
  const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  darkModeMediaQuery.addEventListener('change', (e) => systemDarkMode.value = e.matches);

  if (window.utools) {
    window.utools.onPluginEnter((action) => {
      enterAction.value = action;
    });
  }
});
</script>

<template>
  <div class="app-root">
    <HomeView :enterAction="enterAction" />
  </div>
</template>

<style>
/* Modern Reset & Variables */
:root {
  /* Colors */
  --primary: #ff4778;
  /* Bangumi Pink */
  --primary-hover: #ff7aa0;
  --bg-body: #f7f8fa;
  --bg-card: #ffffff;
  --text-main: #2b2b2b;
  --text-sub: #888888;
  --border: #eaebed;
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.04);
  --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.06);
  --radius-md: 12px;
  --radius-sm: 8px;
  --font-sans: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}

[data-theme='dark'] {
  --bg-body: #121212;
  --bg-card: #1e1e1e;
  --text-main: #eeeeee;
  --text-sub: #a0a0a0;
  --border: #2d2d2d;
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.3);
  --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.4);
}

* {
  box-sizing: border-box;
  -webkit-tap-highlight-color: transparent;
}

html,
body {
  margin: 0;
  padding: 0;
  font-family: var(--font-sans);
  background-color: var(--bg-body);
  color: var(--text-main);
  transition: background 0.3s ease, color 0.3s ease;
  overflow-x: hidden;
}

/* Scrollbar */
::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

::-webkit-scrollbar-thumb {
  background: rgba(136, 136, 136, 0.3);
  border-radius: 3px;
}

::-webkit-scrollbar-track {
  background: transparent;
}
</style>
<script setup>
import { ref, onMounted, computed } from 'vue';
import { getCalendar, getSubject } from '../api/bangumi';
import AnimeCard from './AnimeCard.vue';

const loading = ref(true);
const calendarData = ref([]);
const activeDayId = ref(0);
const selectedItem = ref(null);
const showDetail = ref(false);

const calendarMap = computed(() => {
    const map = {};
    calendarData.value.forEach(day => {
        // Sort items by collection.doing (watching count) descending
        const sortedItems = [...day.items].sort((a, b) => {
            const countA = a.collection?.doing || 0;
            const countB = b.collection?.doing || 0;
            return countB - countA;
        });
        map[day.weekday.id] = sortedItems;
    });
    return map;
});

const sortedWeekDays = computed(() => {
    return [...calendarData.value].sort((a, b) => a.weekday.id - b.weekday.id);
});

const maxRatingCount = computed(() => {
    if (!selectedItem.value?.rating?.count) return 0;
    const counts = Object.values(selectedItem.value.rating.count);
    return Math.max(...counts, 0);
});

const getBarHeight = (score) => {
    if (!selectedItem.value?.rating?.count || maxRatingCount.value === 0) return '0%';
    const count = selectedItem.value.rating.count[score] || 0;
    // Min height 4px to be visible if count > 0, else accurate percentage
    const pct = (count / maxRatingCount.value) * 100;
    return `${pct}%`;
};

const currentItems = computed(() => {
    return calendarMap.value[activeDayId.value] || [];
});

const fetchInit = async () => {
    loading.value = true;
    try {
        const res = await getCalendar();
        if (res) {
            calendarData.value = res;
            const jsDay = new Date().getDay();
            const bgmDay = jsDay === 0 ? 7 : jsDay;
            activeDayId.value = bgmDay;
        }
    } catch (e) {
        console.error(e);
    } finally {
        loading.value = false;
    }
};

const openDetail = async (item) => {
    selectedItem.value = item;
    showDetail.value = true;

    try {
        const detail = await getSubject(item.id);
        if (detail) {
            selectedItem.value = { ...item, ...detail };
        }
    } catch (e) {
        console.error("Failed to fetch subject details", e);
    }
};

const closeDetail = () => {
    showDetail.value = false;
    // Delay clearing for animation
    setTimeout(() => {
        selectedItem.value = null;
    }, 300);
};

const openInBrowser = () => {
    if (!selectedItem.value) return;
    const url = `https://bgm.tv/subject/${selectedItem.value.id}`;
    if (window.utools) {
        window.utools.shellOpenExternal(url);
    } else {
        window.open(url, '_blank');
    }
};

onMounted(() => {
    fetchInit();
});
</script>

<template>
    <div class="page-container">
        <!-- Tabs -->
        <div class="tabs-scroll-area">
            <div class="tabs-wrapper" v-if="!loading">
                <button v-for="day in sortedWeekDays" :key="day.weekday.id" class="tab-pill"
                    :class="{ active: activeDayId === day.weekday.id }" @click="activeDayId = day.weekday.id">
                    {{ day.weekday.cn }}
                </button>
            </div>
        </div>

        <!-- Content Grid -->
        <main class="content-area">
            <div v-if="loading" class="loader-wrapper">
                <div class="spinner"></div>
            </div>

            <div v-else-if="currentItems.length > 0" class="anime-grid">
                <AnimeCard v-for="item in currentItems" :key="item.id" :item="item" @click="openDetail" />
            </div>

            <div v-else class="empty-state">
                <div class="empty-icon">( ˘_˘ )</div>
                <p>今天没有放送哦</p>
            </div>
        </main>

        <!-- Detail Modal -->
        <Transition name="fade">
            <div v-if="showDetail && selectedItem" class="modal-backdrop" @click.self="closeDetail">
                <div class="modal-card">
                    <button class="close-btn" @click="closeDetail">×</button>

                    <div class="modal-header">
                        <div class="poster-container">
                            <img :src="selectedItem.images?.large || selectedItem.images?.common" alt="Poster"
                                class="poster-img">
                            <div class="rank-badge" v-if="selectedItem.rank">#{{ selectedItem.rank }}</div>
                        </div>
                        <div class="info-container">
                            <h2 class="modal-title">{{ selectedItem.name_cn || selectedItem.name }}</h2>
                            <h3 class="modal-subtitle" v-if="selectedItem.name_cn">{{ selectedItem.name }}</h3>

                            <div class="tags-row">
                                <span class="tag-pill" v-if="selectedItem.air_date">{{ selectedItem.air_date }}
                                    放送</span>
                                <span class="tag-pill score" v-if="selectedItem.rating?.score">★ {{
                                    selectedItem.rating.score }} ({{ selectedItem.rating.total }}人评分)</span>
                            </div>

                            <div class="tags-row" v-if="selectedItem.tags">
                                <span class="tag-pill outline" v-for="tag in selectedItem.tags.slice(0, 5)"
                                    :key="tag.name">
                                    {{ tag.name }}
                                </span>
                            </div>

                            <div class="stats-grid">
                                <div class="stat-item" v-if="selectedItem.collection?.doing">
                                    <div class="stat-val">{{ selectedItem.collection.doing }}</div>
                                    <div class="stat-label">在看</div>
                                </div>
                                <div class="stat-item" v-if="selectedItem.collection?.wish">
                                    <div class="stat-val">{{ selectedItem.collection.wish }}</div>
                                    <div class="stat-label">想看</div>
                                </div>
                                <div class="stat-item" v-if="selectedItem.collection?.collect">
                                    <div class="stat-val">{{ selectedItem.collection.collect }}</div>
                                    <div class="stat-label">看过</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="modal-body">
                        <!-- Rating Chart -->
                        <div class="rating-section" v-if="selectedItem.rating?.count">
                            <div class="rating-chart">
                                <div class="chart-col" v-for="i in 10" :key="11 - i">
                                    <!-- Loop 10 down to 1 -->
                                    <div class="bar-track">
                                        <span class="bar-count">{{ selectedItem.rating.count[11 - i] || '' }}</span>
                                        <div class="bar-fill" :style="{ height: getBarHeight(11 - i) }"
                                            :title="(selectedItem.rating.count[11 - i] || 0) + ' votes'"></div>
                                    </div>
                                    <span class="bar-label">{{ 11 - i }}</span>
                                </div>
                            </div>
                        </div>

                        <h4>简介</h4>
                        <p class="summary-text">{{ selectedItem.summary || '暂无简介' }}</p>
                    </div>

                    <div class="modal-footer">
                        <button class="action-btn primary" @click="openInBrowser">在 Bangumi 查看</button>
                    </div>
                </div>
            </div>
        </Transition>
    </div>
</template>

<style scoped>
.page-container {
    height: 100vh;
    display: flex;
    flex-direction: column;
}

.header {
    padding: 16px 20px 8px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.header h1 {
    font-size: 20px;
    font-weight: 700;
    margin: 0;
    color: var(--text-main);
}

.indicator {
    font-size: 12px;
    color: var(--text-sub);
}

.tabs-scroll-area {
    padding: 8px 20px 16px;
    overflow-x: auto;
    scrollbar-width: none;
    -ms-overflow-style: none;
    flex-shrink: 0;
}

.tabs-scroll-area::-webkit-scrollbar {
    display: none;
}

.tabs-wrapper {
    display: flex;
    gap: 10px;
    justify-content: center;
}

.tab-pill {
    appearance: none;
    border: none;
    background: var(--bg-card);
    color: var(--text-sub);
    padding: 6px 16px;
    border-radius: 20px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    box-shadow: var(--shadow-sm);
    border: 1px solid var(--border);
    white-space: nowrap;
    transition: all 0.2s ease;
}

.tab-pill:hover {
    background: var(--bg-body);
    color: var(--text-main);
    transform: translateY(-1px);
}

.tab-pill.active {
    background: var(--primary);
    color: #fff;
    border-color: var(--primary);
    box-shadow: 0 4px 10px rgba(255, 71, 120, 0.3);
}

.content-area {
    flex: 1;
    overflow-y: auto;
    padding: 0 20px 20px;
    position: relative;
}

.anime-grid {
    display: grid;
    /* Increased min-width from 130px to 160px for better fit */
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: 16px;
    padding-bottom: 40px;
}

.loader-wrapper {
    display: flex;
    justify-content: center;
    padding-top: 60px;
}

.spinner {
    width: 32px;
    height: 32px;
    border: 3px solid rgba(0, 0, 0, 0.1);
    border-top-color: var(--primary);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
}

[data-theme='dark'] .spinner {
    border-color: rgba(255, 255, 255, 0.1);
    border-top-color: var(--primary);
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}

.empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding-top: 80px;
    color: var(--text-sub);
}

.empty-icon {
    font-size: 48px;
    margin-bottom: 12px;
    opacity: 0.5;
}

/* Modal Styles */
.modal-backdrop {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.6);
    backdrop-filter: blur(4px);
    z-index: 100;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
}

.modal-card {
    background: var(--bg-card);
    width: 100%;
    max-width: 500px;
    max-height: 85vh;
    border-radius: 20px;
    box-shadow: var(--shadow-md);
    position: relative;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slideUp {
    from {
        transform: translateY(20px);
        opacity: 0;
    }

    to {
        transform: translateY(0);
        opacity: 1;
    }
}

.close-btn {
    position: absolute;
    top: 12px;
    right: 12px;
    width: 32px;
    height: 32px;
    border-radius: 50%;
    background: rgba(0, 0, 0, 0.1);
    border: none;
    font-size: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    z-index: 10;
    color: var(--text-main);
    transition: background 0.2s;
}

.close-btn:hover {
    background: rgba(0, 0, 0, 0.2);
}

[data-theme='dark'] .close-btn {
    background: rgba(255, 255, 255, 0.1);
}

[data-theme='dark'] .close-btn:hover {
    background: rgba(255, 255, 255, 0.2);
}

.modal-header {
    padding: 24px 24px 0;
    display: flex;
    gap: 20px;
}

.poster-container {
    flex-shrink: 0;
    width: 120px;
    position: relative;
}

.poster-img {
    width: 100%;
    border-radius: var(--radius-sm);
    box-shadow: var(--shadow-sm);
    aspect-ratio: 5/7;
    object-fit: cover;
}

.rank-badge {
    position: absolute;
    top: -6px;
    left: -6px;
    background: #ffd700;
    color: #000;
    font-size: 12px;
    font-weight: 800;
    padding: 2px 6px;
    border-radius: 6px;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
}

.info-container {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-width: 0;
    /* Text truncation fix */
}

.modal-title {
    margin: 0;
    font-size: 18px;
    font-weight: 700;
    line-height: 1.3;
    color: var(--text-main);
    margin-bottom: 4px;
}

.modal-subtitle {
    margin: 0;
    font-size: 13px;
    color: var(--text-sub);
    font-weight: 400;
    margin-bottom: 12px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.tags-row {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    margin-bottom: 16px;
}

.tag-pill {
    background: var(--bg-body);
    color: var(--text-sub);
    font-size: 12px;
    padding: 2px 8px;
    border-radius: 6px;
    border: 1px solid var(--border);
}

.tag-pill.score {
    background: #fff8e6;
    color: #f59e0b;
    border-color: #fde68a;
    font-weight: 600;
}

.tag-pill.outline {
    background: transparent;
    border: 1px solid var(--border);
    color: var(--text-sub);
}

[data-theme='dark'] .tag-pill.score {
    background: #453000;
    border-color: #785200;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
}

.stat-item {
    text-align: center;
    background: var(--bg-body);
    padding: 6px;
    border-radius: 8px;
}

.stat-val {
    font-size: 14px;
    font-weight: 700;
    color: var(--text-main);
}

.stat-label {
    font-size: 10px;
    color: var(--text-sub);
}

.modal-body {
    padding: 20px 24px;
    overflow-y: auto;
    flex: 1;
}

.rating-section {
    margin-bottom: 24px;
    padding: 12px 0;
    border-bottom: 1px solid var(--border);
}

.rating-chart {
    display: flex;
    justify-content: space-between;
    height: 100px;
    align-items: flex-end;
    gap: 2px;
}

.chart-col {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    height: 100%;
}

.bar-track {
    flex: 1;
    width: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-end;
}

.bar-count {
    font-size: 10px;
    color: var(--text-sub);
    margin-bottom: 2px;
    line-height: 1;
    font-weight: 500;
}

.bar-fill {
    width: 85%;
    background-color: var(--primary);
    border-radius: 2px 2px 0 0;
    min-height: 1px;
    transition: height 0.3s ease;
    opacity: 0.9;
}

.bar-label {
    font-size: 10px;
    color: var(--text-sub);
    font-family: monospace;
}

.modal-body h4 {
    margin: 0 0 8px 0;
    font-size: 14px;
    color: var(--text-main);
}

.summary-text {
    margin: 0;
    font-size: 14px;
    line-height: 1.6;
    color: var(--text-sub);
    white-space: pre-wrap;
}

.modal-footer {
    padding: 16px 24px 24px;
    border-top: 1px solid var(--border);
}

.action-btn {
    width: 100%;
    padding: 12px;
    border: none;
    border-radius: 12px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.1s;
}

.action-btn.primary {
    background: var(--primary);
    color: white;
    box-shadow: 0 4px 12px rgba(255, 71, 120, 0.3);
}

.action-btn:active {
    transform: scale(0.98);
}

/* Transition */
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>
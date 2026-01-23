<script setup>
import { ref, onMounted, computed } from 'vue';
import { getCalendar, getSubject, getComments } from '../api/bangumi';
import AnimeCard from './AnimeCard.vue';

const loading = ref(true);
const calendarData = ref([]);
const activeDayId = ref(0);
const selectedItem = ref(null);
const isDetailPage = ref(false);
const detailLoading = ref(false);
const isSummaryExpanded = ref(false);

// Comments state
const comments = ref([]);
const commentsTotal = ref(0);
const commentsLoading = ref(false);
const commentsOffset = ref(0);
const commentsLimit = 20;

const formatTime = (ts) => {
    if (!ts) return '';
    const now = Date.now() / 1000;
    const diff = now - ts;
    if (diff < 60) return '刚刚';
    if (diff < 3600) return `${Math.floor(diff / 60)}分钟前`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}小时前`;
    if (diff < 2592000) return `${Math.floor(diff / 86400)}天前`;
    return new Date(ts * 1000).toLocaleDateString().replace(/\//g, '-');
};

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

const fetchComments = async (isLoadMore = false) => {
    if (!selectedItem.value) return;
    commentsLoading.value = true;
    try {
        const offset = isLoadMore ? commentsOffset.value : 0;
        // getComments is defined in api
        const res = await getComments(selectedItem.value.id, commentsLimit, offset);
        if (res && res.data) {
            if (isLoadMore) {
                comments.value = [...comments.value, ...res.data];
            } else {
                comments.value = res.data;
            }
            commentsTotal.value = res.total || 0;
            commentsOffset.value = offset + res.data.length;
        }
    } catch (e) {
        console.error("Failed to fetch comments", e);
    } finally {
        commentsLoading.value = false;
    }
};

const openDetail = async (item) => {
    selectedItem.value = item;
    isDetailPage.value = true;
    detailLoading.value = true;

    // Reset comments
    comments.value = [];
    commentsTotal.value = 0;
    commentsOffset.value = 0;

    // Fetch comments asynchronously without blocking UI
    fetchComments();

    try {
        const detail = await getSubject(item.id);
        if (detail) {
            selectedItem.value = { ...item, ...detail };
        }
    } catch (e) {
        console.error("Failed to fetch subject details", e);
    } finally {
        detailLoading.value = false;
    }
};

const closeDetail = () => {
    isDetailPage.value = false;
    detailLoading.value = false;
    selectedItem.value = null;
    isSummaryExpanded.value = false;
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
        <div v-if="!isDetailPage" class="tabs-scroll-area">
            <div class="tabs-wrapper" v-if="!loading">
                <button v-for="day in sortedWeekDays" :key="day.weekday.id" class="tab-pill"
                    :class="{ active: activeDayId === day.weekday.id }" @click="activeDayId = day.weekday.id">
                    {{ day.weekday.cn }}
                </button>
            </div>
        </div>

        <!-- Content Grid -->
        <main v-if="!isDetailPage" class="content-area">
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

        <Transition name="slide-fade">
            <section v-if="isDetailPage" class="detail-page">
                <header class="detail-topbar">
                    <button class="nav-btn back" @click="closeDetail">
                        <span class="icon">➜</span> 返回列表
                    </button>
                    <button class="nav-btn bangumi" :disabled="!selectedItem" @click="openInBrowser">
                        在 Bangumi 查看 <span class="icon">↗</span>
                    </button>
                </header>

                <div v-if="detailLoading" class="detail-loading">
                    <div class="spinner"></div>
                </div>

                <div v-else-if="selectedItem" class="detail-layout">
                    <div class="detail-hero">
                        <div class="hero-left">
                            <img :src="selectedItem.images?.large || selectedItem.images?.common" alt="Poster"
                                class="hero-poster">
                            <div class="rank-badge" v-if="selectedItem.rank">#{{ selectedItem.rank }}</div>
                        </div>

                        <div class="hero-info">
                            <h2 class="detail-title">{{ selectedItem.name_cn || selectedItem.name }}</h2>
                            <p class="detail-subtitle" v-if="selectedItem.name_cn">{{ selectedItem.name }}</p>

                            <div class="tags-row">
                                <span class="tag-pill" v-if="selectedItem.air_date">{{ selectedItem.air_date }}
                                    放送</span>
                                <span class="tag-pill score" v-if="selectedItem.rating?.score">★ {{
                                    selectedItem.rating.score }}
                                    ({{ selectedItem.rating.total }}人评分)</span>
                            </div>

                            <div class="tags-row" v-if="selectedItem.tags">
                                <span class="tag-pill outline" v-for="tag in selectedItem.tags.slice(0, 6)"
                                    :key="tag.name">
                                    {{ tag.name }}
                                </span>
                            </div>

                            <div class="stats-row-container">
                                <div class="stats-group">
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

                                <div class="mini-rating-chart" v-if="selectedItem.rating?.count">
                                    <div class="chart-col" v-for="i in 10" :key="11 - i">
                                        <div class="bar-track">
                                            <div class="bar-text count" :style="{ bottom: getBarHeight(11 - i) }">{{
                                                selectedItem.rating.count[11 - i] || '' }}</div>
                                            <div class="bar-fill" :style="{ height: getBarHeight(11 - i) }"></div>
                                        </div>
                                        <div class="bar-text label">{{ 11 - i }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="detail-body">
                        <div class="summary-block" :class="{ expanded: isSummaryExpanded }">
                            <h4 class="section-title">简介</h4>
                            <div class="summary-content">
                                <p class="summary-text">{{ selectedItem.summary || '暂无简介' }}</p>
                            </div>
                            <div class="summary-toggle" v-if="selectedItem.summary && selectedItem.summary.length > 100"
                                @click="isSummaryExpanded = !isSummaryExpanded">
                                {{ isSummaryExpanded ? '收起' : '展开更多' }}
                            </div>
                        </div>

                        <div class="comments-section" v-if="comments.length > 0 || commentsLoading">
                            <h4 class="section-title">评论 <span class="count-badge" v-if="commentsTotal">({{
                                commentsTotal }})</span></h4>

                            <div class="comments-list">
                                <div class="comment-item" v-for="comment in comments" :key="comment.id">
                                    <div class="avatar-col">
                                        <img :src="comment.user?.avatar?.medium || comment.user?.avatar?.small"
                                            class="avatar" loading="lazy">
                                    </div>
                                    <div class="comment-content">
                                        <div class="comment-top">
                                            <div class="user-info">
                                                <span class="nickname">{{ comment.user?.nickname ||
                                                    comment.user?.username }}</span>
                                                <span class="rating-label" v-if="comment.rate">★{{ comment.rate
                                                }}</span>
                                            </div>
                                            <span class="comment-date">{{ formatTime(comment.updatedAt) }}</span>
                                        </div>
                                        <div class="comment-text">{{ comment.comment }}</div>
                                    </div>
                                </div>
                            </div>

                            <div class="load-more-container" v-if="comments.length < commentsTotal">
                                <button class="load-more-btn" @click="fetchComments(true)" :disabled="commentsLoading">
                                    {{ commentsLoading ? '加载中...' : '加载更多' }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
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

.detail-page {
    flex: 1;
    overflow-y: auto;
    padding: 12px 20px 24px;
    display: flex;
    flex-direction: column;
    gap: 12px;
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

.detail-topbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: var(--bg-body);
    z-index: 5;
}

.nav-btn {
    border: none;
    background: var(--bg-card);
    color: var(--text-main);
    padding: 6px 12px;
    border-radius: 6px;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: all 0.2s ease;
    box-shadow: var(--shadow-sm);
    border: 1px solid var(--border);
}

.nav-btn:hover {
    transform: translateY(-1px);
    box-shadow: var(--shadow-md);
    background: var(--bg-card);
}

.nav-btn.back .icon {
    font-size: 12px;
    transform: rotate(180deg);
    display: inline-block;
}

.nav-btn.bangumi {
    color: var(--primary);
    background: rgba(255, 71, 120, 0.1);
    border-color: transparent;
}

.nav-btn.bangumi:hover {
    background: rgba(255, 71, 120, 0.15);
}

.nav-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: none;
}

.detail-layout {
    display: flex;
    flex-direction: column;
    gap: 16px;
}

.detail-hero {
    display: grid;
    grid-template-columns: 200px 1fr;
    gap: 20px;
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 16px;
    padding: 16px;
    box-shadow: var(--shadow-sm);
}

.hero-left {
    position: relative;
    width: 100%;
}

.hero-poster {
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

.hero-info {
    display: flex;
    flex-direction: column;
    gap: 12px;
    min-width: 0;
}

.detail-title {
    margin: 0;
    font-size: 22px;
    font-weight: 800;
    color: var(--text-main);
}

.detail-subtitle {
    margin: 0;
    font-size: 14px;
    color: var(--text-sub);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.tags-row {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
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
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 10px;
}

.stat-item {
    text-align: center;
    background: var(--bg-body);
    padding: 8px;
    border-radius: 10px;
}

.stat-val {
    font-size: 16px;
    font-weight: 700;
    color: var(--text-main);
}

.stat-label {
    font-size: 11px;
    color: var(--text-sub);
}

.detail-body {
    display: flex;
    flex-direction: column;
    gap: 16px;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 10px;
    display: none;
    /* Hide old class usage */
}

/* New Layout Styles */
.stats-row-container {
    display: flex;
    align-items: flex-end;
    gap: 24px;
    margin-top: auto;
    /* Push to bottom */
    padding-top: 12px;
    flex-wrap: wrap;
}

.stats-group {
    display: flex;
    gap: 12px;
}

.stat-item {
    text-align: center;
    background: var(--bg-body);
    padding: 6px 10px;
    border-radius: 8px;
    min-width: 50px;
}

/* Ensure stat val and label are styled */
.stat-val {
    font-size: 15px;
    font-weight: 700;
    color: var(--text-main);
    line-height: 1.2;
}

.stat-label {
    font-size: 11px;
    color: var(--text-sub);
}

.mini-rating-chart {
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    gap: 0;
    /* Removed gap */
    height: auto;
    flex: 1;
    min-width: 280px;
    /* Give it enough width */
    margin-left: auto;
    /* Push to right if space permits */
}

.mini-rating-chart .chart-col {
    display: flex;
    flex-direction: column;
    align-items: center;
    flex: 1;
    gap: 2px;
}

.mini-rating-chart .bar-track {
    width: 100%;
    height: 64px;
    /* Slightly increased for better proportions */
    display: flex;
    align-items: flex-end;
    justify-content: center;
    position: relative;
    /* For absolute positioning of count */
    margin-top: 14px;
    /* Reserve space for floating text */
}

.mini-rating-chart .bar-fill {
    width: 92%;
    /* Increased width to reduce gap */
    background-color: #ff6b8b;
    /* Softer pink/primary default */
    border-radius: 3px 3px 0 0;
    min-height: 2px;
    opacity: 1;
    transition: height 0.3s ease;
}

/* Ensure empty bars are barely visible line or just min-height */

.bar-text {
    font-size: 11px;
    color: var(--text-sub);
    line-height: 1;
    white-space: nowrap;
}

.bar-text.count {
    position: absolute;
    width: 200%;
    /* Allow overflow */
    left: -50%;
    text-align: center;
    margin-bottom: 4px;
    /* Gap from top of bar */
    color: var(--text-sub);
    font-weight: 500;
    font-size: 10px;
    pointer-events: none;
}

.bar-text.label {
    margin-top: 4px;
    font-size: 11px;
    color: #999;
}

/* Remove old chart label styles */
.chart-label {
    display: none;
}

.summary-block {
    padding: 16px;
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 14px;
    box-shadow: var(--shadow-sm);
    transition: all 0.3s ease;
}

.summary-content {
    max-height: 120px;
    /* Default collapsed height */
    overflow: hidden;
    position: relative;
    transition: max-height 0.4s ease;
}

.summary-block.expanded .summary-content {
    max-height: 1000px;
    /* Arbitrary large height */
}

/* Fade out effect when collapsed */
.summary-block:not(.expanded) .summary-content::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 0;
    width: 100%;
    height: 60px;
    background: linear-gradient(to bottom, transparent, var(--bg-card));
    pointer-events: none;
}

.summary-toggle {
    text-align: center;
    font-size: 13px;
    color: var(--primary);
    font-weight: 600;
    cursor: pointer;
    margin-top: 8px;
    padding-top: 8px;
    border-top: 1px dashed var(--border);
}

.summary-toggle:hover {
    color: var(--primary-hover);
}

.section-title {
    margin: 0 0 12px 0;
    font-size: 15px;
    color: var(--text-main);
}

.comments-section {
    padding: 16px;
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 14px;
    box-shadow: var(--shadow-sm);
}

.count-badge {
    color: var(--text-sub);
    font-size: 13px;
    font-weight: 500;
}

.comments-list {
    display: flex;
    flex-direction: row;
    /* Changed from column to row */
    flex-wrap: wrap;
    /* Allow wrapping */
    gap: 10px;
}

.comment-item {
    display: flex;
    gap: 10px;
    padding: 10px 14px;
    background: var(--bg-body);
    /* Bubble background */
    border-radius: 16px;
    border: none;
    width: fit-content;
    max-width: 100%;
}

.comment-item:last-child {
    padding-bottom: 10px;
    /* Reset padding override */
    border-bottom: none;
}

.avatar-col {
    flex-shrink: 0;
}

.avatar {
    width: 32px;
    /* Slightly smaller */
    height: 32px;
    border-radius: 50%;
    object-fit: cover;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.comment-content {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: 2px;
}

.comment-top {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.user-info {
    display: flex;
    align-items: center;
    gap: 6px;
}

.nickname {
    font-size: 11px;
    font-weight: 500;
    color: var(--text-sub);
    /* Weaken nickname focus as requested */
}

.comment-date {
    font-size: 11px;
    color: var(--text-sub);
    opacity: 0.8;
    margin-left: 5px;
}

.comment-text {
    font-size: 14px;
    /* Slightly larger text */
    line-height: 1.4;
    color: var(--text-main);
    word-break: break-word;
}

.rating-label {
    font-size: 10px;
    color: #fff;
    background: #ffd700;
    padding: 1px 5px;
    border-radius: 4px;
    font-weight: 700;
    display: inline-flex;
    align-items: center;
    line-height: 1.2;
    text-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
}

[data-theme='dark'] .rating-label {
    color: #000;
}

.load-more-container {
    display: flex;
    justify-content: center;
    margin-top: 16px;
    padding-top: 8px;
    border-top: 1px solid var(--border);
}

.load-more-btn {
    background: transparent;
    border: 1px solid var(--border);
    color: var(--primary);
    padding: 8px 24px;
    border-radius: 20px;
    font-size: 13px;
    cursor: pointer;
    transition: all 0.2s;
}

.load-more-btn:hover:not(:disabled) {
    background: var(--primary);
    color: white;
    border-color: var(--primary);
}

.load-more-btn:disabled {
    opacity: 0.5;
    cursor: wait;
}

/* Removed old rating chart styles */

.summary-text {
    margin: 0;
    font-size: 14px;
    line-height: 1.6;
    color: var(--text-sub);
    white-space: pre-wrap;
}

.detail-loading {
    display: flex;
    justify-content: center;
    padding: 60px 0;
}

/* Transition */
.slide-fade-enter-active,
.slide-fade-leave-active {
    transition: opacity 0.2s ease, transform 0.2s ease;
}

.slide-fade-enter-from,
.slide-fade-leave-to {
    opacity: 0;
    transform: translateY(6px);
}

button {
    line-height: 1.5;
}
</style>
<script setup>
import { ref, onMounted, computed, watch, onUnmounted, nextTick } from 'vue';
import { getCalendar, getSubject, getComments, searchSubjects, getPopularAnime } from '../api/bangumi';
import AnimeCard from './AnimeCard.vue';
import gsap from 'gsap';
import { Flip } from 'gsap/Flip';

gsap.registerPlugin(Flip);
window.Flip = Flip;
window.gsap = gsap;

const loading = ref(true);
const calendarData = ref([]);
const activeDayId = ref(0);
const selectedItem = ref(null);
const isDetailPage = ref(false);
const detailLoading = ref(false);
const isSummaryExpanded = ref(false);

// 主导航状态：calendar(每日放送), popular(热门), ranked(排行榜), search(搜索)
const activeTab = ref('calendar');

// 搜索相关状态
const searchKeyword = ref('');
const searchResults = ref([]);
const searchTotal = ref(0);
const searchLoading = ref(false);
const searchOffset = ref(0);
const searchLimit = 24;
let searchDebounceTimer = null;

// 热门番剧状态
const popularAnime = ref([]);
const popularTotal = ref(0);
const popularLoading = ref(false);
const popularOffset = ref(0);

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

// 搜索功能
const doSearch = async (isLoadMore = false) => {
    if (!searchKeyword.value.trim()) {
        searchResults.value = [];
        searchTotal.value = 0;
        return;
    }
    searchLoading.value = true;
    try {
        const offset = isLoadMore ? searchOffset.value : 0;
        const res = await searchSubjects(searchKeyword.value.trim(), {
            sort: 'match',
            limit: searchLimit,
            offset
        });
        if (res && res.data) {
            if (isLoadMore) {
                searchResults.value = [...searchResults.value, ...res.data];
            } else {
                searchResults.value = res.data;
            }
            searchTotal.value = res.total || 0;
            searchOffset.value = offset + res.data.length;
        }
    } catch (e) {
        console.error('搜索失败:', e);
    } finally {
        searchLoading.value = false;
    }
};

// 防抖搜索
const handleSearchInput = (e) => {
    searchKeyword.value = e.target.value;
    // 清除之前的定时器
    if (searchDebounceTimer) {
        clearTimeout(searchDebounceTimer);
    }
    // 设置新的防抖定时器 (300ms)
    searchDebounceTimer = setTimeout(() => {
        searchOffset.value = 0;
        doSearch();
    }, 300);
};

// 清除搜索
const clearSearch = () => {
    searchKeyword.value = '';
    searchResults.value = [];
    searchTotal.value = 0;
    searchOffset.value = 0;
    if (searchDebounceTimer) {
        clearTimeout(searchDebounceTimer);
    }
};

// 获取热门番剧（按在看人数排序）
const fetchPopular = async (isLoadMore = false) => {
    popularLoading.value = true;
    try {
        const offset = isLoadMore ? popularOffset.value : 0;
        const res = await getPopularAnime(24, offset);
        if (res && res.data) {
            // 按在看人数排序
            const sortedData = [...res.data].sort((a, b) => {
                const countA = a.collection?.doing || 0;
                const countB = b.collection?.doing || 0;
                return countB - countA;
            });
            if (isLoadMore) {
                popularAnime.value = [...popularAnime.value, ...sortedData];
            } else {
                popularAnime.value = sortedData;
            }
            popularTotal.value = res.total || 0;
            popularOffset.value = offset + res.data.length;
        }
    } catch (e) {
        console.error('获取热门番剧失败:', e);
    } finally {
        popularLoading.value = false;
    }
};

// 监听主标签切换，按需加载数据
watch(activeTab, (newTab) => {
    if (newTab === 'popular' && popularAnime.value.length === 0) {
        fetchPopular();
    }
});

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

const openDetail = async (item, event) => {
    // GSAP Flip: Capture state of the clicked item's image and title
    const imgId = `[data-flip-id="img-${item.id}"]`;
    const txtId = `[data-flip-id="txt-${item.id}"]`;
    // Select both elements
    const elements = document.querySelectorAll(`${imgId}, ${txtId}`);

    // Capture state with specific properties for text smoother transition
    const state = Flip.getState(elements, { props: "fontSize,color" });

    selectedItem.value = item;
    isDetailPage.value = true;
    detailLoading.value = true;

    // Reset comments
    comments.value = [];
    commentsTotal.value = 0;
    commentsOffset.value = 0;

    // Wait for DOM update so Detail View is rendered
    await nextTick();

    // Find the target elements in the new view
    const targetElements = document.querySelectorAll(`${imgId}, ${txtId}`);

    if (state.targets.length && targetElements.length) {
        // Animate from list position to detail position
        Flip.from(state, {
            targets: targetElements, // Explicitly target the new elements
            duration: 0.5,
            ease: "power3.inOut",
            absolute: true,
            zIndex: 1000,
            scale: true
        });
    }

    // Fetch comments asynchronously
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

const closeDetail = async () => {
    if (!selectedItem.value) {
        isDetailPage.value = false;
        return;
    }

    const itemId = selectedItem.value.id;
    // GSAP Flip: Capture state of the detail image (only image for closing)
    const imgId = `[data-flip-id="img-${itemId}"]`;

    // Capture state of only the image
    const state = Flip.getState(imgId);

    isDetailPage.value = false;
    detailLoading.value = false;
    isSummaryExpanded.value = false;

    // Wait for DOM update so List View is rendered
    await nextTick();

    const targetElement = document.querySelector(imgId);

    if (state.targets.length && targetElement) {
        // Fix for clipping: find parents and allow overflow
        const card = targetElement.closest('.card');
        const coverWrapper = targetElement.closest('.cover-wrapper');

        const originalOverflow = card ? card.style.overflow : '';
        const originalZIndex = card ? card.style.zIndex : '';
        const originalPosition = card ? card.style.position : '';
        const originalWrapperOverflow = coverWrapper ? coverWrapper.style.overflow : '';

        if (card) {
            card.style.overflow = 'visible';
            card.style.zIndex = '1001';
            // Ensure z-index works
            if (getComputedStyle(card).position === 'static') {
                card.style.position = 'relative';
            }
        }

        if (coverWrapper) {
            coverWrapper.style.overflow = 'visible';
        }

        // Animate back to list position
        Flip.from(state, {
            targets: targetElement,
            duration: 0.4,
            ease: "power3.inOut",
            absolute: true,
            zIndex: 1000,
            scale: true,
            simple: true,
            onComplete: () => {
                selectedItem.value = null;
                if (card) {
                    card.style.overflow = originalOverflow;
                    card.style.zIndex = originalZIndex;
                    card.style.position = originalPosition;
                }
                if (coverWrapper) {
                    coverWrapper.style.overflow = originalWrapperOverflow;
                }
            }
        });
    } else {
        selectedItem.value = null;
    }
};

const getBackText = () => {
    switch (activeTab.value) {
        case 'calendar': return '返回列表';
        case 'popular': return '返回热门';
        case 'search': return '返回搜索';
        default: return '返回列表';
    }
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

onUnmounted(() => {
    // 清理防抖定时器
    if (searchDebounceTimer) {
        clearTimeout(searchDebounceTimer);
    }
});
</script>

<template>
    <div class="page-container">
        <!-- 主导航栏 -->
        <nav v-if="!isDetailPage" class="main-nav">
            <div class="nav-tabs">
                <button class="nav-tab" :class="{ active: activeTab === 'calendar' }" @click="activeTab = 'calendar'">
                    <span class="nav-icon">📅</span> 每日放送
                </button>
                <button class="nav-tab" :class="{ active: activeTab === 'popular' }" @click="activeTab = 'popular'">
                    <span class="nav-icon">🔥</span> 热门番剧
                </button>
                <button class="nav-tab" :class="{ active: activeTab === 'search' }" @click="activeTab = 'search'">
                    <span class="nav-icon">🔍</span> 搜索
                </button>
            </div>
        </nav>

        <!-- 每日放送 Tabs -->
        <div v-if="!isDetailPage && activeTab === 'calendar'" class="tabs-scroll-area">
            <div class="tabs-wrapper" v-if="!loading">
                <button v-for="day in sortedWeekDays" :key="day.weekday.id" class="tab-pill"
                    :class="{ active: activeDayId === day.weekday.id }" @click="activeDayId = day.weekday.id">
                    {{ day.weekday.cn }}
                </button>
            </div>
        </div>

        <!-- 搜索栏 -->
        <div v-if="!isDetailPage && activeTab === 'search'" class="search-bar-area">
            <div class="search-input-wrapper">
                <span class="search-icon">🔍</span>
                <input type="text" class="search-input" placeholder="输入番剧名称搜索..." :value="searchKeyword"
                    @input="handleSearchInput">
                <span v-if="searchLoading" class="search-loading">⏳</span>
                <button v-else-if="searchKeyword" class="search-clear-btn" @click="clearSearch" title="清除">
                    ✕
                </button>
            </div>
            <div class="search-hint" v-if="searchTotal > 0">
                找到 {{ searchTotal }} 个结果
            </div>
        </div>

        <!-- 每日放送内容 -->
        <main v-if="!isDetailPage && activeTab === 'calendar'" class="content-area">
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

        <!-- 热门番剧内容 -->
        <main v-if="!isDetailPage && activeTab === 'popular'" class="content-area">
            <div v-if="popularLoading && popularAnime.length === 0" class="loader-wrapper">
                <div class="spinner"></div>
            </div>

            <template v-else>
                <div v-if="popularAnime.length > 0" class="anime-grid">
                    <AnimeCard v-for="item in popularAnime" :key="item.id" :item="item" @click="openDetail" />
                </div>

                <div v-else class="empty-state">
                    <div class="empty-icon">( ˘_˘ )</div>
                    <p>暂无热门番剧数据</p>
                </div>

                <div class="load-more-container" v-if="popularAnime.length < popularTotal">
                    <button class="load-more-btn" @click="fetchPopular(true)" :disabled="popularLoading">
                        {{ popularLoading ? '加载中...' : '加载更多' }}
                    </button>
                </div>
            </template>
        </main>

        <!-- 搜索结果内容 -->
        <main v-if="!isDetailPage && activeTab === 'search'" class="content-area">
            <div v-if="searchLoading && searchResults.length === 0" class="loader-wrapper">
                <div class="spinner"></div>
            </div>

            <template v-else>
                <div v-if="searchResults.length > 0" class="anime-grid">
                    <AnimeCard v-for="item in searchResults" :key="item.id" :item="item" @click="openDetail" />
                </div>

                <div v-else-if="searchKeyword && !searchLoading" class="empty-state">
                    <div class="empty-icon">( ˘_˘ )</div>
                    <p>没有找到相关番剧</p>
                </div>

                <div v-else class="empty-state search-hint-state">
                    <div class="empty-icon">🔍</div>
                    <p>输入关键词搜索你喜欢的番剧</p>
                </div>

                <div class="load-more-container" v-if="searchResults.length > 0 && searchResults.length < searchTotal">
                    <button class="load-more-btn" @click="doSearch(true)" :disabled="searchLoading">
                        {{ searchLoading ? '加载中...' : '加载更多' }}
                    </button>
                </div>
            </template>
        </main>

        <!-- 详情页 -->
        <section v-if="isDetailPage" class="detail-page">
            <header class="detail-topbar">
                <button class="nav-btn back" @click="closeDetail">
                    <span class="icon">➜</span> {{ getBackText() }}
                </button>
                <button class="nav-btn bangumi" :disabled="!selectedItem" @click="openInBrowser">
                    在 Bangumi 查看 <span class="icon">↗</span>
                </button>
            </header>

            <div v-if="detailLoading && !selectedItem" class="detail-loading">
                <div class="spinner"></div>
            </div>

            <div v-else-if="selectedItem" class="detail-layout">
                <div class="detail-hero">
                    <div class="hero-left" ref="heroImageRef">
                        <img :src="selectedItem.images?.large || selectedItem.images?.common" alt="Poster"
                            class="hero-poster" :data-flip-id="'img-' + selectedItem.id" />
                        <div class="rank-badge" v-if="selectedItem.rank">#{{ selectedItem.rank }}</div>
                    </div>

                    <div class="hero-info">
                        <h2 class="detail-title" :data-flip-id="'txt-' + selectedItem.id">{{ selectedItem.name_cn ||
                            selectedItem.name }}</h2>

                        <div class="tags-row">
                            <span class="tag-pill" v-if="selectedItem.air_date">{{ selectedItem.air_date }}
                                放送</span>
                            <span class="tag-pill score" v-if="selectedItem.rating?.score">★ {{
                                selectedItem.rating.score }}
                                ({{ selectedItem.rating.total }}人评分)</span>
                        </div>

                        <div class="tags-row" v-if="selectedItem.tags">
                            <span class="tag-pill outline" v-for="tag in selectedItem.tags.slice(0, 6)" :key="tag.name">
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
    </div>
</template>

<style scoped>
.page-container {
    height: 100vh;
    display: flex;
    flex-direction: column;
}

/* 主导航栏 */
.main-nav {
    padding: 12px 0;
    background: var(--bg-card);
    border-bottom: 1px solid var(--border);
    flex-shrink: 0;
    display: flex;
    justify-content: center;
}

.nav-tabs {
    display: inline-flex;
    gap: 8px;
    padding: 0 12px;
}

.nav-tab {
    appearance: none;
    border: none;
    background: var(--bg-body);
    color: var(--text-sub);
    padding: 8px 16px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: all 0.2s ease;
    border: 1px solid transparent;
}

.nav-tab:hover {
    background: var(--bg-card);
    color: var(--text-main);
    border-color: var(--border);
}

.nav-tab.active {
    background: var(--primary);
    color: #fff;
    border-color: var(--primary);
    box-shadow: 0 2px 8px rgba(255, 71, 120, 0.25);
}

.nav-icon {
    font-size: 14px;
}

/* 搜索栏 */
.search-bar-area {
    padding: 16px 20px;
    flex-shrink: 0;
}

.search-input-wrapper {
    display: flex;
    align-items: center;
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 4px 8px 4px 14px;
    box-shadow: var(--shadow-sm);
    transition: all 0.2s ease;
}

.search-input-wrapper:focus-within {
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(255, 71, 120, 0.1);
}

.search-icon {
    font-size: 16px;
    margin-right: 10px;
    opacity: 0.6;
}

.search-input {
    flex: 1;
    border: none;
    background: transparent;
    font-size: 14px;
    color: var(--text-main);
    outline: none;
    padding: 8px 0;
}

.search-input::placeholder {
    color: var(--text-sub);
}

.search-clear-btn {
    appearance: none;
    border: none;
    background: transparent;
    color: var(--text-sub);
    font-size: 14px;
    width: 32px;
    height: 32px;
    border-radius: 50%;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s ease;
    margin-right: 4px;
}

.search-clear-btn:hover {
    background: var(--bg-body);
    color: var(--text-main);
}

.search-loading {
    font-size: 14px;
    margin-right: 8px;
    animation: pulse 1s ease-in-out infinite;
}

@keyframes pulse {

    0%,
    100% {
        opacity: 1;
    }

    50% {
        opacity: 0.5;
    }
}

.search-hint {
    margin-top: 10px;
    font-size: 13px;
    color: var(--text-sub);
    text-align: center;
}

.search-hint-state {
    padding-top: 40px;
}

.search-hint-state .empty-icon {
    font-size: 56px;
    opacity: 0.8;
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
    padding-bottom: 20px;
}

/* 内容区域底部加载更多按钮 */
.content-area>.load-more-container {
    display: flex;
    justify-content: center;
    padding: 20px 0 40px;
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
    aspect-ratio: 5/7;
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

/* 共享元素转场动画 */
.shared-cover {
    overflow: hidden;
    box-shadow: var(--shadow-md);
    pointer-events: none;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
}

.shared-cover img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

/* 共享标题转场动画 */
.shared-title {
    color: var(--text-main);
    pointer-events: none;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    line-height: 1.3;
}

/* 详情页封面和标题隐藏（用共享元素代替） */
.hero-poster.invisible,
.detail-title.invisible {
    opacity: 0 !important;
    visibility: hidden;
}

/* 详情页进入动画 */
.detail-fade-enter-active {
    transition: opacity 0.35s cubic-bezier(0.4, 0, 0.2, 1);
}

.detail-fade-leave-active {
    transition: opacity 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

.detail-fade-enter-from,
.detail-fade-leave-to {
    opacity: 0;
}

/* 详情页内容动画 */
.detail-page .detail-topbar,
.detail-page .hero-info,
.detail-page .detail-body {
    animation: content-fade-in 0.4s cubic-bezier(0.4, 0, 0.2, 1) forwards;
    animation-delay: 0.1s;
    opacity: 0;
}

@keyframes content-fade-in {
    from {
        opacity: 0;
        transform: translateY(10px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}

/* 原有的 slide-fade 保留给其他用途 */
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
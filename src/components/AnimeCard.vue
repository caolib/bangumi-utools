<script setup>
const props = defineProps({
    item: {
        type: Object,
        required: true
    }
});

const emit = defineEmits(['click']);

const getCover = (images) => {
    if (!images) return '';
    return images.large || images.common || images.medium || images.grid;
};
</script>

<template>
    <div class="card" @click="emit('click', item)">
        <div class="cover-wrapper">
            <img :src="getCover(item.images)" loading="lazy" alt="cover" />
            <div class="rating" v-if="item.rating && item.rating.score">
                {{ item.rating.score }}
            </div>
        </div>
        <div class="content">
            <h3 class="title" :title="item.name_cn || item.name">{{ item.name_cn || item.name }}</h3>
            <div class="meta">
                <span class="date" v-if="item.air_date">{{ item.air_date }}</span>
                <span class="count" v-if="item.collection?.doing">{{ item.collection.doing }} 人在看</span>
            </div>
        </div>
    </div>
</template>

<style scoped>
.card {
    background: var(--bg-card);
    border-radius: var(--radius-md);
    overflow: hidden;
    box-shadow: var(--shadow-sm);
    transition: box-shadow 0.2s ease;
    cursor: pointer;
    border: 1px solid var(--border);
    display: flex;
    flex-direction: column;
}

.card:hover {
    box-shadow: var(--shadow-md);
}

.cover-wrapper {
    position: relative;
    width: 100%;
    padding-top: 140%;
    /* 5:7 aspect ratio */
    background: #f0f0f0;
    overflow: hidden;
}

[data-theme='dark'] .cover-wrapper {
    background: #2a2a2a;
}

.cover-wrapper img {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.5s ease;
}

.card:hover .cover-wrapper img {
    transform: scale(1.05);
}

.rating {
    position: absolute;
    top: 6px;
    right: 6px;
    background: var(--primary);
    color: #fff;
    font-size: 12px;
    font-weight: 700;
    padding: 3px 8px;
    /* Slightly larger padding */
    border-radius: 12px;
    /* Pill shape */
    backdrop-filter: blur(8px);
    /* stronger blur */
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.15);
    display: flex;
    align-items: center;
    gap: 3px;
    line-height: 1;
}

.rating::before {
    content: '★';
    color: #fff;
    font-size: 11px;
}

.content {
    padding: 10px 12px;
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
}

.title {
    margin: 0 0 6px 0;
    font-size: 14px;
    font-weight: 600;
    line-height: 1.4;
    color: var(--text-main);

    /* 2 line clamp */
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

.meta {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 11px;
    color: var(--text-sub);
}
</style>
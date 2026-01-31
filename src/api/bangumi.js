const API_BASE = 'https://api.bgm.tv';
const API_NEXT = 'https://next.bgm.tv';

const USER_AGENT = 'bangumi-utools/1.0.0 (https://github.com/caolib/bangumi-utools)';

async function fetchAPI(endpoint, apiBase = API_BASE) {
    const res = await fetch(`${apiBase}${endpoint}`, {
        headers: {
            'Accept': 'application/json',
            'User-Agent': USER_AGENT
        }
    });
    if (!res.ok) {
        throw new Error(`API Error: ${res.status} ${res.statusText}`);
    }
    return res.json();
}

async function postAPI(endpoint, body, apiBase = API_BASE) {
    const res = await fetch(`${apiBase}${endpoint}`, {
        method: 'POST',
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'User-Agent': USER_AGENT
        },
        body: JSON.stringify(body)
    });
    if (!res.ok) {
        throw new Error(`API Error: ${res.status} ${res.statusText}`);
    }
    return res.json();
}

/**
 * 获取每日放送
 */
export function getCalendar() {
    return fetchAPI('/calendar');
}

/**
 * 获取条目详情
 * @param {number} id 
 */
export function getSubject(id) {
    return fetchAPI(`/v0/subjects/${id}`);
}

/**
 * 获取条目评论
 * @param {number} id Subject ID
 * @param {number} limit 
 * @param {number} offset 
 */
export function getComments(id, limit = 20, offset = 0) {
    return fetchAPI(`/p1/subjects/${id}/comments?limit=${limit}&offset=${offset}`, API_NEXT);
}

/**
 * 搜索番剧
 * @param {string} keyword 搜索关键词
 * @param {object} options 搜索选项
 * @param {string} options.sort 排序方式: match, heat, rank, score
 * @param {number} options.limit 每页数量
 * @param {number} options.offset 偏移量
 * @param {number[]} options.type 类型过滤: 1=书籍, 2=动画, 3=音乐, 4=游戏, 6=三次元
 */
export function searchSubjects(keyword, options = {}) {
    const { sort = 'match', limit = 20, offset = 0, type = [2] } = options;
    const body = {
        keyword,
        sort,
        filter: {
            type
        }
    };
    return postAPI(`/v0/search/subjects?limit=${limit}&offset=${offset}`, body);
}

/**
 * 获取近期热门番剧（当前季度新番，按热度排序）
 * 相当于 Bangumi 网页版的"近期注目"
 * @param {number} limit 每页数量
 * @param {number} offset 偏移量
 */
export function getPopularAnime(limit = 24, offset = 0) {
    // 获取当前季度的开始日期
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;
    
    // 计算当前季度：1-3月=1月, 4-6月=4月, 7-9月=7月, 10-12月=10月
    let seasonStartMonth;
    if (month <= 3) seasonStartMonth = 1;
    else if (month <= 6) seasonStartMonth = 4;
    else if (month <= 9) seasonStartMonth = 7;
    else seasonStartMonth = 10;
    
    // 往前推一个季度，以包含更多新番
    let startYear = year;
    let startMonth = seasonStartMonth - 3;
    if (startMonth <= 0) {
        startMonth += 12;
        startYear -= 1;
    }
    
    const startDate = `${startYear}-${String(startMonth).padStart(2, '0')}-01`;

    const body = {
        keyword: '',
        sort: 'heat',
        filter: {
            type: [2], // 动画类型
            air_date: [`>=${startDate}`] // 当前季度及上季度的番剧
        }
    };
    return postAPI(`/v0/search/subjects?limit=${limit}&offset=${offset}`, body);
}

/**
 * 获取高分番剧（按评分排序）
 * @param {number} limit 每页数量
 * @param {number} offset 偏移量
 */
export function getTopRatedAnime(limit = 24, offset = 0) {
    const body = {
        keyword: '',
        sort: 'score',
        filter: {
            type: [2],
            rank: ['>=1'] // 必须有排名的才算有效
        }
    };
    return postAPI(`/v0/search/subjects?limit=${limit}&offset=${offset}`, body);
}


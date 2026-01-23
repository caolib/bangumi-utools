const API_BASE = 'https://api.bgm.tv';
const API_NEXT = 'https://next.bgm.tv';

async function fetchAPI(endpoint, apiBase = API_BASE) {
    const res = await fetch(`${apiBase}${endpoint}`, {
        headers: {
            'Accept': 'application/json'
        }
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

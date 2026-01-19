const API_BASE = 'https://api.bgm.tv';

async function fetchAPI(endpoint) {
    const res = await fetch(`${API_BASE}${endpoint}`, {
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

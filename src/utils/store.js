/**
 * uTools dbStorage 封装
 * 提供简单的 get/set 接口用于数据持久化
 */

/**
 * 从 uTools dbStorage 中获取数据
 * @param {string} key - 键名
 * @param {*} defaultValue - 默认值
 * @returns {*} 存储的值或默认值
 */
export function getData(key, defaultValue = null) {
    try {
        const value = window.utools.dbStorage.getItem(key)
        return value !== null && value !== undefined ? value : defaultValue
    } catch (error) {
        console.error(`获取数据失败 [${key}]:`, error)
        return defaultValue
    }
}

/**
 * 向 uTools dbStorage 中存储数据
 * @param {string} key - 键名
 * @param {*} value - 要存储的值
 * @returns {boolean} 是否存储成功
 */
export function setData(key, value) {
    try {
        window.utools.dbStorage.setItem(key, value)
        return true
    } catch (error) {
        console.error(`存储数据失败 [${key}]:`, error)
        return false
    }
}

/**
 * 从 uTools dbStorage 中删除数据
 * @param {string} key - 键名
 * @returns {boolean} 是否删除成功
 */
export function removeData(key) {
    try {
        window.utools.dbStorage.removeItem(key)
        return true
    } catch (error) {
        console.error(`删除数据失败 [${key}]:`, error)
        return false
    }
}

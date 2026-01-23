# 获取条目评论

## OpenAPI Specification

```yaml
openapi: 3.0.1
info:
  title: ''
  version: 1.0.0
paths:
  /p1/subjects/{subject_id}/comments:
    get:
      summary: 获取条目评论
      deprecated: false
      description: ''
      tags: []
      parameters:
        - name: subject_id
          in: path
          description: ''
          required: true
          example: '515759'
          schema:
            type: string
        - name: limit
          in: query
          description: ''
          required: false
          example: '20'
          schema:
            type: string
        - name: offset
          in: query
          description: ''
          required: false
          example: '0'
          schema:
            type: string
      responses:
        '200':
          description: ''
          content:
            application/json:
              schema:
                type: object
                properties: {}
              example:
                data:
                  - id: 47299047
                    user:
                      id: 990697
                      username: '990697'
                      nickname: 四字神人258
                      avatar:
                        small: https://lain.bgm.tv/pic/user/s/icon.jpg
                        medium: https://lain.bgm.tv/pic/user/m/icon.jpg
                        large: https://lain.bgm.tv/pic/user/l/icon.jpg
                      group: 10
                      sign: ''
                      joinedAt: 1743842802
                    type: 3
                    rate: 7
                    comment: 第一集算过渡
                    updatedAt: 1769134920
                  - id: 47296822
                    user:
                      id: 754656
                      username: '754656'
                      nickname: 笑冷孤叶
                      avatar:
                        small: https://lain.bgm.tv/pic/user/s/icon.jpg
                        medium: https://lain.bgm.tv/pic/user/m/icon.jpg
                        large: https://lain.bgm.tv/pic/user/l/icon.jpg
                      group: 10
                      sign: ''
                      joinedAt: 1672889146
                    type: 3
                    rate: 8
                    comment: 好看依旧，快把黄金乡和女神之碑端上来吧
                    updatedAt: 1769111123
                  - id: 47295351
                    user:
                      id: 638258
                      username: fuyuuuutu
                      nickname: 不憂鬱
                      avatar:
                        small: >-
                          https://lain.bgm.tv/pic/user/s/000/63/82/638258.jpg?r=1732424333&hd=1
                        medium: >-
                          https://lain.bgm.tv/pic/user/m/000/63/82/638258.jpg?r=1732424333&hd=1
                        large: >-
                          https://lain.bgm.tv/pic/user/l/000/63/82/638258.jpg?r=1732424333&hd=1
                      group: 10
                      sign: 充满信心 满怀期待
                      joinedAt: 1634658067
                    type: 3
                    rate: 8
                    comment: 感觉第一集的色彩有点怪？fll这块金字招牌还是相信再相信吧
                    updatedAt: 1769104260
                  - id: 33904207
                    user:
                      id: 665384
                      username: '665384'
                      nickname: 隐隐约约一样
                      avatar:
                        small: https://lain.bgm.tv/pic/user/s/icon.jpg
                        medium: https://lain.bgm.tv/pic/user/m/icon.jpg
                        large: https://lain.bgm.tv/pic/user/l/icon.jpg
                      group: 10
                      sign: 我永远喜欢王琪琪。！
                      joinedAt: 1643723055
                    type: 3
                    rate: 6
                    comment: //第一话：老样子、慢节奏，看后面怎么样吧。
                    updatedAt: 1769087020
                  - id: 47284588
                    user:
                      id: 874351
                      username: '874351'
                      nickname: 打磨仙人
                      avatar:
                        small: >-
                          https://lain.bgm.tv/pic/user/s/000/87/43/874351.jpg?r=1714729797&hd=1
                        medium: >-
                          https://lain.bgm.tv/pic/user/m/000/87/43/874351.jpg?r=1714729797&hd=1
                        large: >-
                          https://lain.bgm.tv/pic/user/l/000/87/43/874351.jpg?r=1714729797&hd=1
                      group: 10
                      sign: ''
                      joinedAt: 1714727186
                    type: 3
                    rate: 8
                    comment: 现在这样就很好了
                    updatedAt: 1769082068
                  - id: 47276081
                    user:
                      id: 606840
                      username: '606840'
                      nickname: Eridosym
                      avatar:
                        small: >-
                          https://lain.bgm.tv/pic/user/s/000/60/68/606840.jpg?r=1712921485&hd=1
                        medium: >-
                          https://lain.bgm.tv/pic/user/m/000/60/68/606840.jpg?r=1712921485&hd=1
                        large: >-
                          https://lain.bgm.tv/pic/user/l/000/60/68/606840.jpg?r=1712921485&hd=1
                      group: 10
                      sign: ''
                      joinedAt: 1624703145
                    type: 3
                    rate: 8
                    comment: 音乐 凯尔特 西幻 喜欢
                    updatedAt: 1769057324
                  - id: 47265016
                    user:
                      id: 898482
                      username: '898482'
                      nickname: 八奈见杏菜
                      avatar:
                        small: >-
                          https://lain.bgm.tv/pic/user/s/000/89/84/898482.jpg?r=1721873207&hd=1
                        medium: >-
                          https://lain.bgm.tv/pic/user/m/000/89/84/898482.jpg?r=1721873207&hd=1
                        large: >-
                          https://lain.bgm.tv/pic/user/l/000/89/84/898482.jpg?r=1721873207&hd=1
                      group: 10
                      sign: ''
                      joinedAt: 1721870184
                    type: 2
                    rate: 8
                    comment: 延续高水平制作和叙事风格
                    updatedAt: 1769010919
                  - id: 47264070
                    user:
                      id: 374554
                      username: '374554'
                      nickname: Ira
                      avatar:
                        small: >-
                          https://lain.bgm.tv/pic/user/s/000/37/45/374554.jpg?r=1752103349&hd=1
                        medium: >-
                          https://lain.bgm.tv/pic/user/m/000/37/45/374554.jpg?r=1752103349&hd=1
                        large: >-
                          https://lain.bgm.tv/pic/user/l/000/37/45/374554.jpg?r=1752103349&hd=1
                      group: 10
                      sign: ''
                      joinedAt: 1509319394
                    type: 3
                    rate: 10
                    comment: ep1.还是一样无敌的节奏，我的时间被偷走了，饭还没吃完就结束了TAT
                    updatedAt: 1769009015
                  - id: 47262709
                    user:
                      id: 494479
                      username: animeing
                      nickname: '549'
                      avatar:
                        small: >-
                          https://lain.bgm.tv/pic/user/s/000/49/44/494479.jpg?r=1671782238&hd=1
                        medium: >-
                          https://lain.bgm.tv/pic/user/m/000/49/44/494479.jpg?r=1671782238&hd=1
                        large: >-
                          https://lain.bgm.tv/pic/user/l/000/49/44/494479.jpg?r=1671782238&hd=1
                      group: 10
                      sign: 奔跑吧梅洛斯
                      joinedAt: 1566782735
                    type: 5
                    rate: 0
                    comment: 有钱的少年番。太温吞了算了
                    updatedAt: 1769006305
                  - id: 47259700
                    user:
                      id: 1202942
                      username: '1202942'
                      nickname: loran
                      avatar:
                        small: https://lain.bgm.tv/pic/user/s/icon.jpg
                        medium: https://lain.bgm.tv/pic/user/m/icon.jpg
                        large: https://lain.bgm.tv/pic/user/l/icon.jpg
                      group: 10
                      sign: ''
                      joinedAt: 1768999074
                    type: 3
                    rate: 8
                    comment: good
                    updatedAt: 1769002831
                total: 583
          headers: {}
          x-apifox-name: 成功
          x-apifox-ordering: 0
      security: []
      x-apifox-folder: ''
      x-apifox-status: developing
      x-run-in-apifox: https://app.apifox.com/web/project/7751960/apis/api-409743566-run
components:
  schemas: {}
  responses: {}
  securitySchemes: {}
servers:
  - url: https://next.bgm.tv
    description: https://next.bgm.tv
security: []

```
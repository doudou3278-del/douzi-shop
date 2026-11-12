# DOUZI Custom Minifigs — 网站上线步骤

这个文件夹就是一个完整的网站，不需要编译，直接上传就能用。

| 文件 | 作用 |
|---|---|
| `index.html` | 商店首页（入场动画 + 商品 + 联系方式） |
| `admin.html` | 商家后台（登录后管理商品、图片、微信号） |
| `config.js` | 填写你的 Supabase 地址和公开密钥 |
| `setup.sql` | 一次性建好数据库、权限和图片存储 |
| `img/` | 现在两件商品的图片 |

整体结构：**GitHub** 存代码 → **GitHub Pages** 或 **Cloudflare Pages** 把它变成公开网站 → **Supabase** 存商品数据和图片。三者都有免费额度，小店基本不花钱。

---

## 第一步：建数据库（Supabase）

1. 打开 https://supabase.com 注册（可以直接用 GitHub 账号登录），点 **New project**。
   - 名字随便填，比如 `douzi`；数据库密码自己记好；Region 选离顾客近的。
2. 等项目建好后，左侧点 **SQL Editor → New query**，把 `setup.sql` 的全部内容粘贴进去，点 **Run**。
3. 左侧点 **Authentication → Users → Add user → Create new user**，填你自己的邮箱和一个密码，勾选 *Auto Confirm User*。这就是你登录后台的账号。
4. 回到 **SQL Editor**，运行这一句（把邮箱换成你刚才填的）：
   ```sql
   insert into public.admins (user_id) select id from auth.users where email = '你的邮箱';
   ```
5. 为了安全，到 **Authentication → Sign In / Providers**（或 Settings），把 **Allow new users to sign up** 关掉，这样别人不能自己注册。
6. 左侧点 **Project Settings → API**（有的版本叫 Data API / API Keys），复制两个值：
   - **Project URL**（像 `https://abcd1234.supabase.co`）
   - **anon public key**（很长的一串）
7. 用记事本打开 `config.js`，把这两个值替换进去，保存。

> anon public key 本来就是设计成公开放在网页里的，安全由 `setup.sql` 里的权限规则保证：任何人都只能看上架商品，只有管理员能改。
> **绝对不要**把 `service_role` 密钥放进任何文件或上传到 GitHub。

---

## 第二步：上传到 GitHub

1. 打开 https://github.com 注册并登录。
2. 右上角 **＋ → New repository**，名字填比如 `douzi-shop`，选 **Public**，点 **Create repository**。
3. 在新仓库页面点 **uploading an existing file**，把这个文件夹里的**所有文件和 img 文件夹**一起拖进去（注意是拖文件夹里面的内容，不是外面那层文件夹），点 **Commit changes**。

以后要改网站，只要在 GitHub 上替换对应的文件，网站会自动更新。

---

## 第三步：变成公开网站（二选一）

### 方法 A：GitHub Pages（最简单）
1. 在仓库里点 **Settings → Pages**。
2. **Source** 选 *Deploy from a branch*，Branch 选 `main`，文件夹选 `/ (root)`，点 **Save**。
3. 等一两分钟，页面顶部会出现网址，类似 `https://你的用户名.github.io/douzi-shop/`。

### 方法 B：Cloudflare Pages（速度通常更快，绑定域名更方便）
1. 打开 https://dash.cloudflare.com 注册，进入 **Workers & Pages → Create → Pages → Connect to Git**。
2. 授权 GitHub，选择 `douzi-shop` 仓库。
3. Framework preset 选 **None**，Build command 留空，Build output directory 填 `/`，点 **Save and Deploy**。
4. 得到网址 `https://douzi-shop.pages.dev`。以后你每次在 GitHub 改文件，它会自动重新发布。

---

## 第四步：试一下

- 打开网站首页，应该能看到入场动画和两件商品。
- 打开 `网址/admin.html`（首页最底部也有 *Merchant login* 链接），用第一步创建的邮箱密码登录。
- 试着下架一个商品，刷新首页，它应该消失；再上架回来。

## 可选：绑定自己的域名
在 Namecheap、Cloudflare 等处买域名（如 `douzicustoms.com`），然后：
- GitHub Pages：Settings → Pages → Custom domain；
- Cloudflare Pages：项目 → Custom domains → Set up a domain。
按页面提示设置即可。

## 常见问题
- **首页显示的是旧商品 / 后台改了首页没变**：检查 `config.js` 是否已填写并上传到 GitHub。没填时首页会显示内置的两件商品。
- **后台提示"这个账号还不是管理员"**：重新运行第一步第 4 条那句 SQL，邮箱要和登录用的完全一致。
- **图片上传失败**：确认 `setup.sql` 全部运行成功（里面创建了 `product-images` 存储桶）。

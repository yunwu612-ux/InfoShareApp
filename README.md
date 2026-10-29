# InfoShare App V1.0

公开资料共享应用：Android Flutter 客户端 + React 管理后台 + Supabase 云端数据库/图片存储。

## 功能
- 手机端：公开浏览、搜索、分类、标签、详情、图片画廊、下拉刷新
- 管理后台：管理员登录、新建/编辑/发布/下架/删除资料、图片上传、分类与标签
- 云端：Supabase Postgres + Storage；已发布资料公开读取，写入仅管理员
- 实时：客户端订阅 `articles` 表变更；同时支持手动刷新

## 目录
- `mobile/` Flutter Android/iOS 客户端源代码
- `admin/` Vite + React 管理后台源代码
- `supabase/schema.sql` 数据库表、RLS、Storage bucket 与策略
- `.env.example` 配置模板

## 快速启动

### 1. 建立 Supabase 项目
在 Supabase 创建项目，进入 SQL Editor，执行 `supabase/schema.sql`。
然后在 Authentication -> Users 中创建管理员账号。把该用户 UUID 写入 `profiles` 表，并设置 `role='admin'`：

```sql
insert into public.profiles (id, role, display_name)
values ('管理员用户UUID', 'admin', 'Admin')
on conflict (id) do update set role='admin';
```

在 Supabase Project Settings -> API 获取 Project URL 和 anon/publishable key。

### 2. 手机端
安装 Flutter SDK（Flutter 3.24+），在 `mobile/`：
```bash
cp ../.env.example .env
# 编辑 .env，填入 SUPABASE_URL 和 SUPABASE_ANON_KEY
flutter pub get
flutter run
# Android APK:
flutter build apk --release
```

### 3. 管理后台
在 `admin/`：
```bash
cp .env.example .env
# VITE_SUPABASE_URL 和 VITE_SUPABASE_ANON_KEY
npm install
npm run dev
```
部署可使用 Vercel/Netlify/Cloudflare Pages。后台管理员必须使用 Supabase Auth 登录，不能把 service-role key 放进前端。

## 公开访问与安全
- 访客无需登录即可查看 `published` 内容。
- 新增、编辑、发布、删除与上传图片需要 Supabase Auth 管理员账号。
- 资料公开意味着所有已发布内容及图片可被任何人访问；请勿上传私人信息。
- `anon` key 是公开客户端 key，依赖 RLS；**绝不能把 service-role key 放入手机端或网页端**。

## V1.0 限制
此包是完整可继续构建的源码项目，不包含已编译 APK。当前执行环境没有 Flutter SDK/Android SDK，因此无法在这里产出或验证 APK。配置 Supabase 后，在 Flutter 环境运行 `flutter build apk --release`。

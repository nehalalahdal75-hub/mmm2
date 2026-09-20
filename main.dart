import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const EnjazApp());
}

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('enjaz_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        progress REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE team (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertProject(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('projects', row);
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await instance.database;
    return await db.query('projects', orderBy: 'id DESC');
  }

  Future<int> updateProject(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'projects',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await instance.database;
    await db.delete('tasks', where: 'projectId = ?', whereArgs: [id]);
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertTask(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('tasks', row);
  }

  Future<List<Map<String, dynamic>>> getTasks(int projectId) async {
    final db = await instance.database;
    return await db.query(
      'tasks',
      where: 'projectId = ?',
      whereArgs: [projectId],
    );
  }

  Future<int> updateTaskStatus(int id, int status) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      {'isCompleted': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertTeamMember(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('team', row);
  }

  Future<List<Map<String, dynamic>>> getTeamMembers() async {
    final db = await instance.database;
    return await db.query('team');
  }

  Future<int> deleteTeamMember(int id) async {
    final db = await instance.database;
    return await db.delete('team', where: 'id = ?', whereArgs: [id]);
  }
}

class EnjazApp extends StatelessWidget {
  const EnjazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة إنجاز',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Arial',
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول - منصة إنجاز')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.task_alt, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (val) => val == null || !val.contains('@')
                    ? 'البريد الإلكتروني غير صالح'
                    : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (val) => val == null || val.length < 6
                    ? 'كلمة المرور قصيرة جداً'
                    : null,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  }
                },
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                ),
                child: const Text('إنشاء حساب جديد'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text('نسيت كلمة المرور؟ (OTP)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || !val.contains('@')
                    ? 'أدخل بريداً صحيحاً'
                    : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.length < 6 ? 'كلمة المرور قصيرة' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val != _passController.text
                    ? 'كلمتا المرور غير متطابقتين'
                    : null,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('تسجيل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool codeSent = false;
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور (OTP)')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'أدخل بريدك الإلكتروني',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            if (codeSent) ...[
              TextField(
                controller: _otpCtrl,
                decoration: const InputDecoration(
                  labelText: 'رمز التحقق المرسل (OTP)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
            ],
            ElevatedButton(
              onPressed: () {
                setState(() {
                  codeSent = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      codeSent && _otpCtrl.text.isNotEmpty
                          ? 'تم التحقق بنجاح'
                          : 'تم إرسال رمز التحقق (OTP) إلى بريدك',
                    ),
                  ),
                );
              },
              child: Text(codeSent ? 'تأكيد الرمز' : 'إرسال الرمز'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم - منصة إنجاز')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text(
                'منصة إنجاز للمشاريع',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('لوحة التحكم'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('المشاريع الجماعية'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProjectsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('إدارة الفريق'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('الإشعارات'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('التقارير والإحصائيات'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('الإعدادات'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تأكيد الخروج'),
                    content: const Text(
                      'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'خروج',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'المشاريع النشطة',
              '5',
              Icons.folder_open,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProjectsScreen()),
                );
              },
            ),
            _buildStatCard(
              'المهام المنجزة',
              '12',
              Icons.task,
              Colors.green,
              () {},
            ),
            _buildStatCard('أعضاء الفريق', '4', Icons.group, Colors.orange, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamScreen()),
              );
            }),
            _buildStatCard(
              'الإشعارات',
              '3',
              Icons.notifications_active,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() async {
    final data = await DBHelper.instance.getProjects();
    setState(() {
      _projects = data;
    });
  }

  void _addOrEditProject({Map<String, dynamic>? project}) {
    final titleController = TextEditingController(
      text: project?['title'] ?? '',
    );
    final descController = TextEditingController(
      text: project?['description'] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(project == null ? 'إضافة مشروع جديد' : 'تعديل المشروع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'عنوان المشروع'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'وصف المشروع'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                if (project == null) {
                  await DBHelper.instance.insertProject({
                    'title': titleController.text,
                    'description': descController.text,
                    'progress': 0.0,
                  });
                } else {
                  await DBHelper.instance.updateProject({
                    'id': project['id'],
                    'title': titleController.text,
                    'description': descController.text,
                    'progress': project['progress'],
                  });
                }
                _loadProjects();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteProject(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المشروع نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await DBHelper.instance.deleteProject(id);
              _loadProjects();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح')));
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المشاريع الجماعية')),
      body: _projects.isEmpty
          ? const Center(
              child: Text('لا توجد مشاريع حالياً. أضف مشروعاً جديداً!'),
            )
          : ListView.builder(
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final proj = _projects[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      proj['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(proj['description']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _addOrEditProject(project: proj),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProject(proj['id']),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailsScreen(project: proj),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditProject(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    final tasks = await DBHelper.instance.getTasks(widget.project['id']);
    setState(() {
      _tasks = tasks;
    });
  }

  void _addNewTask() {
    final taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مهمة جديدة'),
        content: TextField(
          controller: taskController,
          decoration: const InputDecoration(labelText: 'اسم المهمة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (taskController.text.isNotEmpty) {
                await DBHelper.instance.insertTask({
                  'projectId': widget.project['id'],
                  'title': taskController.text,
                  'isCompleted': 0,
                });
                _loadTasks();
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project['title'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وصف المشروع: ${widget.project['description']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            const Text(
              'مهام المشروع:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  bool isDone = task['isCompleted'] == 1;
                  return CheckboxListTile(
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    value: isDone,
                    onChanged: (val) async {
                      await DBHelper.instance.updateTaskStatus(
                        task['id'],
                        val! ? 1 : 0,
                      );
                      _loadTasks();
                    },
                    secondary: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await DBHelper.instance.deleteTask(task['id']);
                        _loadTasks();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        child: const Icon(Icons.add_task),
      ),
    );
  }
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<Map<String, dynamic>> _team = [];

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  void _loadTeam() async {
    final data = await DBHelper.instance.getTeamMembers();
    setState(() => _team = data);
  }

  void _addMember() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة عضو للفريق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم العضو'),
            ),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(labelText: 'الدور / التخصص'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await DBHelper.instance.insertTeamMember({
                  'name': nameCtrl.text,
                  'role': roleCtrl.text,
                });
                _loadTeam();
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة أعضاء الفريق')),
      body: ListView.builder(
        itemCount: _team.length,
        itemBuilder: (context, index) {
          final member = _team[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(member['name']),
            subtitle: Text(member['role']),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await DBHelper.instance.deleteTeamMember(member['id']);
                _loadTeam();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMember,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات والتنبيهات')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.indigo),
            title: Text('تم إسناد مهمة جديدة إليك'),
            subtitle: Text('قبل ساعتين'),
          ),
          ListTile(
            leading: Icon(Icons.warning, color: Colors.orange),
            title: Text('موعد تسليم المشروع اقترب'),
            subtitle: Text('أمس'),
          ),
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('تم اكتمال مشروع إنجاز بنجاح'),
            subtitle: Text('منذ 3 أيام'),
          ),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقارير الإنجاح')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                title: Text('نسبة إنجاز المهام العامة'),
                trailing: Text(
                  '75%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                title: Text('المشاريع المكتملة'),
                trailing: Text(
                  '3 مشاريع',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                title: Text('عدد المهام قيد التنفيذ'),
                trailing: Text(
                  '5 مهام',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('الوضع الليلي'),
            value: isDarkMode,
            onChanged: (val) => setState(() => isDarkMode = val),
          ),
          ListTile(
            title: const Text('إصدار التطبيق'),
            trailing: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('حول المنصة'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'منصة إنجاز',
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Routes/rotas.dart';
import 'package:flutter_application_1/Telas/Dashboard/WidgetDashboard.dart';
import 'package:flutter_application_1/Telas/Listagem/WidgetListagem.dart';
import 'package:flutter_application_1/Telas/Login/WidgetLogin.dart';
import 'package:flutter_application_1/Telas/NewContract/NewContract.dart';
import 'package:flutter_application_1/Telas/empresa/WidgetCompanyPage.dart';
import 'package:flutter_application_1/Telas/empresa/WidgetSignCompany.dart';
import 'package:flutter_application_1/Telas/funcionario/WidgetSignUser.dart';
import 'package:flutter_application_1/Telas/funcionario/WidgetUserPage.dart';
import 'package:flutter_application_1/Telas/protocol/ProtocolSearchScreen.dart';
import 'package:flutter_application_1/Telas/unifiedContract/UnifiedContractScreen.dart';
import 'package:flutter_application_1/Telas/InitialScreen.dart';
import 'package:flutter_application_1/Utils/AuthGuard.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const App({key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PagHiper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0857C3),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 216, 216, 216),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: Rotas.home,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      routes: {
        Rotas.home: (context) => const InitialScreen(),
        Rotas.login: (context) => const WidgetLogin(),

        // Rotas protegidas (requerem autenticação)
        Rotas.dashboard: (context) => const AuthenticatedRoute(
              child: WidgetDashboard(),
            ),
        Rotas.upload: (context) => const AuthenticatedRoute(
              child: NewContractScreen(),
            ),
        Rotas.listagem: (context) => const AuthenticatedRoute(
              child: WidgetListagem(),
            ),
        Rotas.unifiedContract: (context) => const AuthenticatedRoute(
              child: UnifiedContractScreen(),
            ),
        Rotas.protocolSearch: (context) => const AuthenticatedRoute(
              child: ProtocolSearchScreen(),
            ),

        // Rotas administrativas (requerem role admin)
        Rotas.signNewUser: (context) => const AdminRoute(
              child: WidgetSignUser(adminUserId: 1),
            ),
        Rotas.usersPage: (context) => const AdminRoute(
              child: WidgetUserPage(adminUserId: 1),
            ),
        Rotas.companiesPage: (context) => const AdminRoute(
              child: WidgetCompanyPage(),
            ),
        Rotas.signNewCompany: (context) => const AdminRoute(
              child: WidgetSignCompany(),
            ),
      },
    );
  }
}

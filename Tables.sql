
-- CREATE SCHEMA projeto;
GO



DROP TABLE IF EXISTS projeto.Toca
DROP TABLE IF EXISTS projeto.Tem
DROP TABLE IF EXISTS projeto.Participa
DROP TABLE IF EXISTS projeto.Grupo
DROP TABLE IF EXISTS projeto.Disciplina
DROP TABLE IF EXISTS projeto.Turma
DROP TABLE IF EXISTS projeto.PertenceDirecao
DROP TABLE IF EXISTS projeto.PertenceTurma
DROP TABLE IF EXISTS projeto.Login
DROP TABLE IF EXISTS projeto.Request
DROP TABLE IF EXISTS projeto.Evento
DROP TABLE IF EXISTS projeto.Aluno
DROP TABLE IF EXISTS projeto.Professor



CREATE TABLE projeto.Toca(
	INTRUMENTO_Nome VARCHAR(30)		NOT NULL,
	ALUNO_Codigo		INT			,
	PROFESSOR_Codigo	SMALLINT	,
)



---------------------------------------------------------
---------------------------------------------------------


CREATE TABLE projeto.Disciplina (
	ID					INT         NOT NULL,
	Nome				VARCHAR(30) NOT NULL,
	PROFESSOR_Codigo	INT			NOT NULL,
	PRIMARY KEY(ID)
)

--------------------------------------------------------
--------------------------------------------------------


CREATE TABLE projeto.Participa(
	Representante		VARCHAR(30) NOT NULL,
	ALUNO_Codigo		INT			,
	PROFESSOR_Codigo	SMALLINT	,
)



---------------------------------------------------------
---------------------------------------------------------

CREATE TABLE projeto.Grupo (
	Representante		VARCHAR(30),
	GRUPO_Tipo			VARCHAR(30),
	PROFESSOR_Codigo	SMALLINT,
	PRIMARY KEY(Representante, PROFESSOR_Codigo)
	
)


---------------------------------------------------------
---------------------------------------------------------

CREATE TABLE projeto.Turma (
	Numero				INT NOT NULL,
	Capacidade			INT NOT NULL,
	DISCILINA_ID		INT NOT NULL,
	PRIMARY KEY(Numero,DISCILINA_ID),
	CHECK(Numero > 0),
	CHECK(Capacidade > 0)
)

----------------------------------------------------------
----------------------------------------------------------

CREATE TABLE projeto.PertenceTurma(
	CODIGO_Aluno INT NOT NULL,
	TURMA_Numero INT NOT NULL,
	PRIMARY KEY(CODIGO_Aluno)
)

--------------------------------------------------------
--------------------------------------------------------

CREATE TABLE projeto.PertenceDirecao(
	CODIGO_Professor	SMALLINT	NOT NULL,
	Ano					INT			NOT NULL,
	Cargo				VARCHAR(30) NOT NULL,
)



	
---------------------------------------------------------
---------------------------------------------------------

CREATE TABLE projeto.Login (
	UserID				INT IDENTITY(1,1) NOT NULL,
	Utilizador			VARCHAR(30) NOT NULL,
	PasswordHash		BINARY(64)	NOT NULL,
	Fname				VARCHAR(30),
	Lname				VARCHAR(30)
	PRIMARY KEY(Utilizador)
)




---------------------------------------------------------
---------------------------------------------------------

CREATE TABLE projeto.Request (
	Ano					INT,	
	PROFESSOR_Codigo	SMALLINT,
	Aceite				BIT NOT NULL ,
	PRIMARY KEY(PROFESSOR_Codigo)
)


---------------------------------------------------------
---------------------------------------------------------

CREATE TABLE projeto.Evento (
	EVENTO_Nome			VARCHAR(30),
	Local				VARCHAR(30)	NOT NULL,
	EVENTO_inicio			DATE,
	EVENTO_fim				DATE,
	Caracteristica		VARCHAR(30) NOT NULL,
	EVENTO_Ano			INT,
	Aceite				BIT			NOT NULL,
	PRIMARY KEY(EVENTO_Nome)

)



---------------------------------------------------------
---------------------------------------------------------

CREATE TABLE projeto.Aluno (
	ALUNO_Codigo		INT IDENTITY(1,1)	NOT NULL,
	Data_Nasc			DATE				NOT NULL,
	Telemovel			VARCHAR(15),
	Nome				VARCHAR(50)			NOT NULL,
	Sexo				VARCHAR(20)			NOT NULL,
	NIF					INT					NOT NULL,
	Email				VARCHAR(100)		NOT NULL,
	Morada				VARCHAR(200)		NOT NULL,
	Mensalidade			INT DEFAULT 25      NOT NULL ,
	TURMA_Numero		INT,
	TURMA_ID			INT,
	PRIMARY KEY CLUSTERED (ALUNO_Codigo),
	CHECK(Mensalidade > 20)
)

SELECT * FROM projeto.Aluno
---------------------------------------------------------
---------------------------------------------------------

CREATE TABLE projeto.Tem (
	ALUNO_Codigo		INT,
	PROFESSOR_Codigo	SMALLINT,
	PRIMARY KEY(ALUNO_Codigo, PROFESSOR_Codigo)

)

---------------------------------------------------------
---------------------------------------------------------

CREATE TABLE projeto.Professor (
	PROFESSOR_Codigo	smallint IDENTITY( 100, 1),
	Data_Nasc			DATE				NOT NULL,
	Telemovel			VARCHAR(15),
	Nome				VARCHAR(50)			NOT NULL,
	Sexo				VARCHAR(20)			NOT NULL,
	NIF					INT					NOT NULL,
	Email				VARCHAR(100)		NOT NULL,
	Morada				VARCHAR(200)		NOT NULL,
	Salario				INT			NOT NULL,
	
	DISCIPLINA_ID		INT,

	PRIMARY KEY(PROFESSOR_Codigo),
	CHECK(Salario > 350)
)
go



---------------------------------------------------------
---------------------------------------------------------



ALTER TABLE projeto.Turma ADD FOREIGN KEY(DISCILINA_ID) REFERENCES projeto.Disciplina(ID)
ALTER TABLE projeto.Tem ADD FOREIGN KEY(ALUNO_Codigo) REFERENCES projeto.Aluno(ALUNO_Codigo)
ALTER TABLE projeto.Tem ADD FOREIGN KEY(PROFESSOR_Codigo) REFERENCES projeto.Professor(PROFESSOR_Codigo)
ALTER TABLE projeto.PertenceTurma ADD FOREIGN KEY(CODIGO_Aluno) REFERENCES projeto.Aluno(ALUNO_Codigo)
ALTER TABLE projeto.Evento ADD FOREIGN KEY(Aceite) REFERENCES projeto.Request(Aceite)



GO








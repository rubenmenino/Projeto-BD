/*	
* Gabriel Saudade 89304
* Ruben Menino 
*
*		Stored Procedures
*/




-----------------------------
-----------------------------
-- o procedimento armazenado pega a senha como par�metro de entrada
-- e insere-a na base de dados em um formato criptografado - HASHBYTES 
-----------------------------
-----------------------------

DROP PROCEDURE projeto.adicionarRegisto
CREATE PROCEDURE projeto.adicionarRegisto
	@pLogin			VARCHAR(30),
	@pPassword		VARCHAR(30),
	@pFirstName				VARCHAR(30),
	@pLastName				VARCHAR(30),
	@responseMessage NVARCHAR(250) OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		INSERT INTO projeto.Login (Utilizador, PasswordHash , Fname, Lname)
		VALUES(@pLogin, HASHBYTES('SHA2_512', @pPassword), @pFirstName, @pLastName)
		SET @responseMessage = 'Success'
	END TRY
	BEGIN CATCH
		SET @responseMessage = ERROR_MESSAGE()
	END CATCH
END

GO
---------------------------
---------------------------

DECLARE @responseMessage NVARCHAR(250)
EXEC projeto.adicionarRegisto
          @pLogin = N'Admin',
          @pPassword = N'123',
          @pFirstName = N'Admin',
          @pLastName = N'Administrator',
          @responseMessage=@responseMessage OUTPUT
go
SELECT * FROM projeto.Login
go

---------------------------
---------------------------
-- alterar atabela e o procedimento armazenado para usar um salt na criptografia de senha. 
-- gerado aleatoriamente e uma sequ�ncia �nica.
---------------------------
---------------------------

GO
ALTER TABLE projeto.Login ADD Salt UNIQUEIDENTIFIER 
GO

ALTER PROCEDURE projeto.adicionarRegisto
    @pLogin NVARCHAR(50), 
    @pPassword NVARCHAR(50),
    @pFirstName NVARCHAR(40) = NULL, 
    @pLastName NVARCHAR(40) = NULL,
    @responseMessage NVARCHAR(250) OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @salt UNIQUEIDENTIFIER=NEWID()
    BEGIN TRY
        INSERT INTO projeto.Login (Utilizador, PasswordHash, Salt, Fname, Lname)
        VALUES(@pLogin, HASHBYTES('SHA2_512', @pPassword+CAST(@salt AS NVARCHAR(36))), @salt, @pFirstName, @pLastName)
       SET @responseMessage='Success'
    END TRY
    BEGIN CATCH
        SET @responseMessage=ERROR_MESSAGE() 
    END CATCH
END

-----------------------------------
-----------------------------------
go

TRUNCATE TABLE projeto.Login
DECLARE @responseMessage NVARCHAR(250)
EXEC projeto.adicionarRegisto
          @pLogin = N'Admin',
          @pPassword = N'123',
          @pFirstName = N'Admin',
          @pLastName = N'Administrator',
          @responseMessage=@responseMessage OUTPUT
SELECT UserID, Utilizador, PasswordHash, Salt, Fname, Lname
FROM projeto.Login

go


-----------------------------------
-----------------------------------
-- Para poder usar o salt para fazer login na base de dados
--
-----------------------------------
-----------------------------------


DROP PROCEDURE projeto.logar
CREATE PROCEDURE projeto.logar
    @pLoginName NVARCHAR(254),
    @pPassword NVARCHAR(50),
    @responseMessage NVARCHAR(250)='' OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @userID INT
    IF EXISTS (SELECT TOP 1 UserID FROM projeto.Login WHERE Utilizador=@pLoginName)
    BEGIN
        SET @userID=(SELECT UserID FROM projeto.Login WHERE Utilizador=@pLoginName AND PasswordHash=HASHBYTES('SHA2_512', @pPassword+CAST(Salt AS NVARCHAR(36))))

       IF(@userID IS NULL)
           SET @responseMessage='Incorrect password'
       ELSE 
           SET @responseMessage='User successfully logged in'
    END
    ELSE
       SET @responseMessage='Invalid login'
END
	

GO


-------------------------------------
-------------------------------------

-- stored procedure para criar um aluno (irrelevante no sentido que se podia Inserir diretamente no c�digo C#)

DROP PROC projeto.criarAluno
CREATE PROC projeto.criarAluno (@Data_Nasc DATE, @Telemovel VARCHAR(15), @Nome VARCHAR(50), @Sexo VARCHAR(20), @NIF INT, @Email VARCHAR(100), @Morada VARCHAR(200), @Mensalidade INT, @TURMA_Numero INT, @TURMA_ID VARCHAR(30))
AS	
	INSERT INTO projeto.Aluno (Data_Nasc, Telemovel, Nome, Sexo, NIF, Email, Morada, Mensalidade, TURMA_Numero, TURMA_disciplina) 
	VALUES (@Data_Nasc, @Telemovel, @Nome, @Sexo, @NIF, @Email, @Morada, @Mensalidade, @TURMA_Numero, @TURMA_ID)\;
GO

-------------------------------------
-------------------------------------

--stored procedure para criar um Professor e inserir o seu c�digo na tabela Toca que faz a rela��o entre uma pessoa e o seu instrumento 

DROP PROC projeto.criarProfessor
CREATE PROC projeto.criarProfessor (@Data_Nasc DATE, @Telemovel VARCHAR(15), @Nome VARCHAR(50), @Sexo VARCHAR(20), @NIF INT, @Email VARCHAR(100), @Morada VARCHAR(200), @Salario INT, @DISCIPLINA_ID INT)
AS
	INSERT INTO projeto.Professor (Data_Nasc, Telemovel, Nome, Sexo, NIF, Email, Morada, Salario, DISCIPLINA_ID) 
	VALUES (@Data_Nasc, @Telemovel, @Nome, @Sexo, @NIF, @Email, @Morada, @Salario, @DISCIPLINA_ID);
	
	DECLARE @id SMALLINT
	SET @id = (SELECT MAX(projeto.Professor.PROFESSOR_Codigo) FROM projeto.Professor)
	
	IF EXISTS(
		SELECT * FROM projeto.Toca
		WHERE @id = PROFESSOR_Codigo
	)
	BEGIN
		DELETE FROM projeto.Toca
		WHERE PROFESSOR_Codigo = @id
	END


	INSERT INTO projeto.TOCA(INTRUMENTO_Nome, ALUNO_Codigo, PROFESSOR_Codigo) VALUES(null, null, @id)

GO

-------------------------------------
-------------------------------------

--stored procedure para adicionar intrumento ao aluno e aos professores

DROP PROC projeto.addInstrumento
CREATE PROC projeto.addInstrumento(@id INT, @instrumento VARCHAR(30))
AS	

	IF @id IS NOT NULL
	BEGIN

		IF @id > 99
		BEGIN 
			IF EXISTS (SELECT PROFESSOR_Codigo FROM projeto.Toca
				WHERE INTRUMENTO_Nome = @instrumento AND ALUNO_Codigo = null)
				BEGIN
					RETURN -1
				END

			UPDATE projeto.Toca 
			SET INTRUMENTO_Nome = @instrumento
			WHERE PROFESSOR_Codigo = @id
		END

		IF @id < 100
		BEGIN
			
			IF  EXISTS (
				SELECT * FROM projeto.Toca
				WHERE ALUNO_Codigo = @id AND INTRUMENTO_Nome = @instrumento
			)
			BEGIN
				PRINT'Aluno j� toca o instrumento selecinado!'
				RETURN 
			END

			INSERT INTO projeto.Toca (INTRUMENTO_Nome, ALUNO_Codigo, PROFESSOR_Codigo) VALUES(@instrumento, @id, NULL)	
		END

			
	END
GO

-------------------------------------
-------------------------------------

-- procedure para atualizar a informa��o do professor

DROP PROC projeto.updateProfessor
CREATE PROC projeto.updateProfessor (@PROFESSOR_Codigo INT, @Data_Nasc DATE, @Telemovel VARCHAR(15), @Nome VARCHAR(50), @Sexo VARCHAR(20), @NIF INT, @Email VARCHAR(100), @Morada VARCHAR(200), @DISCIPLINA_ID INT, @inst VARCHAR(30))
AS
	-- Foi necess�rio incluir esta condi��es pois nos inserts manuais (INSERT.slq) n�o se faz esta verifica��o
	IF NOT EXISTS(
		SELECT PROFESSOR_Codigo FROM projeto.Toca
		WHERE PROFESSOR_Codigo = @PROFESSOR_Codigo
	)
	BEGIN
		INSERT INTO projeto.TOCA(INTRUMENTO_Nome, ALUNO_Codigo, PROFESSOR_Codigo) VALUES(null, null, @PROFESSOR_Codigo)	
	END


	DECLARE @Salario INT


	UPDATE projeto.Professor 
	SET Data_Nasc = @Data_Nasc, Telemovel = @Telemovel, Nome = @Nome, Sexo = @Sexo, NIF = @NIF, Email = @Email, Morada = @Morada, Salario = @Salario
	WHERE PROFESSOR_Codigo = @PROFESSOR_Codigo

	EXEC projeto.addInstrumento @id=@PROFESSOR_Codigo, @instrumento=@inst
GO

-------------------------------------
-------------------------------------

-- procedure para atualizar a informa��o do aluno

DROP PROC projeto.updateAluno
CREATE PROC projeto.updateAluno (@ALUNO_Codigo INT, @Data_Nasc DATE, @Telemovel VARCHAR(15), @Nome VARCHAR(50), @Sexo VARCHAR(20), @NIF INT, @Email VARCHAR(100), @Morada VARCHAR(200), @Mensalidade INT, @TURMA_Numero INT, @TURMA_ID VARCHAR(30), @inst VARCHAR(30))
AS
	

	UPDATE projeto.Aluno
	SET Data_Nasc = @Data_Nasc, Telemovel = @Telemovel, Nome = @Nome, Sexo = @Sexo, NIF = @NIF, Email = @Email, Morada = @Morada, Mensalidade = @Mensalidade, TURMA_Numero = @TURMA_Numero, TURMA_disciplina = @TURMA_ID
	WHERE ALUNO_Codigo = @ALUNO_Codigo

	-- n�o � preciso verificar que existe um instrumento pois essa verifica��o � feita diretamente no c�digo C#
	EXEC projeto.addInstrumento @id=@ALUNO_Codigo, @instrumento=@inst
GO

-------------------------------------
-------------------------------------

-- Remove um professor 

DROP PROC projeto.deleteProfessor


-------------------------------------
-------------------------------------

-- Remove um aluno caso s� toque um instrumento, remove o instrumento selecionado caso contr�rio

DROP PROC projeto.deleteAluno
-------------------------------------
-------------------------------------
-------------------------------------
-------------------------------------

DROP PROC projeto.adicionarAlunoTurma
CREATE PROC projeto.adicionarAlunoTurma(@id INT, @TURMA_Numero INT, @disciplinaID VARCHAR(30))
AS
	IF @id IS NOT NULL
	BEGIN
		IF EXISTS(
			SELECT * FROM projeto.PertenceTurma
			WHERE @id = CODIGO_Aluno AND @TURMA_Numero = TURMA_Numero 
		)
		BEGIN
			print 'Aluno j� pertence � turma!'
			RETURN
		END


		IF NOT EXISTS(
			SELECT ALUNO_Codigo FROM projeto.Aluno
			WHERE ALUNO_Codigo = @id
		)
		BEGIN
			PRINT 'ID do aluno n�o � valido'
			RETURN
		END

		IF NOT EXISTS(
			SELECT CODIGO_Aluno FROM projeto.PertenceTurma
			WHERE CODIGO_Aluno = @id
		)
		BEGIN
			INSERT INTO projeto.PertenceTurma (CODIGO_Aluno, TURMA_Numero) VALUES (@id, @TURMA_Numero)
			RETURN
		END

		UPDATE projeto.PertenceTurma
		SET TURMA_Numero = @TURMA_Numero
		WHERE CODIGO_Aluno = @id

		UPDATE projeto.Aluno
		SET TURMA_disciplina = @disciplinaID, TURMA_Numero = @TURMA_Numero
		WHERE ALUNO_Codigo = @id

	END
	
GO

-------------------------------------
-------------------------------------

--Adiciona um professor a um cargo da dire��o

DROP PROC projeto.addProfessorDirecao

Go

-------------------------------------
-------------------------------------

-- Atualiza o sal�rio do professor na inser��o de um novo aluno

DROP PROC projeto.atualizarSalario
-------------------------------------
CREATE PROC projeto.getAlunosProf(@PROFESSOR_Codigo SMALLINT)
AS

	WHERE INTRUMENTO_Nome = (SELECT INTRUMENTO_Nome FROM projeto.profInst WHERE PROFESSOR_Codigo = @PROFESSOR_Codigo)
-------------------------------------
CREATE PROC projeto.criarGrupo(@representante int, @tipo varchar(30))
AS

IF NOT EXISTS(
		SELECT PROFESSOR_Codigo FROM projeto.Professor
		WHERE PROFESSOR_Codigo = @representante
	)
	BEGIN
		PRINT 'PROFESSOR N�O EXISTE'
		RETURN
	END


IF EXISTS(
		SELECT GRUPO_Tipo FROM projeto.Grupo
		WHERE GRUPO_Tipo = @tipo
	)
		BEGIN
		print'Grupo com o mesmo nome'
		return
	END

	INSERT INTO projeto.Grupo(Representante, GRUPO_Tipo) VALUES (@representante, @tipo )
	

-------------------------------------
-------------------------------------

go 
drop proc projeto.adicionarCodigoGrupo
CREATE PROC projeto.adicionarCodigoGrupo (@codigoP SMALLINT, @codigoA INT, @tipo VARCHAR(30))
AS
	
BEGIN
	declare @representante INT
	SET @representante = (SELECT Representante FROM projeto.Grupo WHERE @tipo = GRUPO_Tipo)
	IF EXISTS (SELECT * FROM projeto.PertenceGrupo
				WHERE @codigoP = CodigoP AND @codigoA = CodigoA)
		BEGIN
			PRINT 'J� pertence ao grupo'
			RETURN
		END

	IF @codigoA > 99
		BEGIN
			INSERT INTO projeto.PertenceGrupo(Representante, GRUPO_Tipo, CodigoP, CodigoA) VALUES (@representante, @tipo, @codigoP, null)
		END

	IF @codigoA < 100
		BEGIN
			INSERT INTO projeto.PertenceGrupo(Representante, GRUPO_Tipo, CodigoP, CodigoA) VALUES (@representante, @tipo, null, @codigoA)
		END	
	
END




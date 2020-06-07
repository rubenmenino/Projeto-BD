--DROP FUNCTION projeto.GetAlunosInstrumento 
--                GO
--                CREATE FUNCTION projeto.GetAlunosInstrumento(@ALUNO_Codigo INT) RETURNS TABLE 
--                AS 
--                RETURN ( Select c.ALUNO_Codigo
--                FROM projeto.Aluno as c JOIN projeto.Toca1 as e ON c.ALUNO_Codigo=e.ALUNO_Codigo
--                WHERE c.ALUNO_Codigo=@ALUNO_Codigo 
                
--                ) 
--                GO 
--                SELECT * FROM GetAlunosInstrumento(3)
--                GO;



--CREATE PROCEDURE projeto.inserirAluno (@Data_Nasc date, @Telemovel VARCHAR(15), @Nome VARCHAR(50), @Sexo varchar(20), 
--@NIF int, @Email VARCHAR(100), @Morada VARCHAR(200), @Mensalidade INT,  @id int OUTPUT)
--AS  
--BEGIN      
--	Insert projeto.Aluno (Data_Nasc, Telemovel, Nome, Sexo, NIF, Email, Morada, Mensalidade) VALUES (@Data_Nasc, @Telemovel, @Nome, @Sexo, 
--							   @NIF, @Email, @Morada, @Mensalidade);  
	
--	SET @id = SCOPE_IDENTITY();  
--END


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
-- Testar
--
-------------------------------------
-------------------------------------

/*
DECLARE	@responseMessage nvarchar(250)

--Correct login and password
EXEC	projeto.logar
		@pLoginName = N'Admin',
		@pPassword = N'123',
		@responseMessage = @responseMessage OUTPUT

SELECT	@responseMessage as N'@responseMessage'

--Incorrect login
EXEC	projeto.logar
		@pLoginName = N'Admin1', 
		@pPassword = N'123',
		@responseMessage = @responseMessage OUTPUT

SELECT	@responseMessage as N'@responseMessage'

--Incorrect password
EXEC	projeto.logar
		@pLoginName = N'Admin', 
		@pPassword = N'1234',
		@responseMessage = @responseMessage OUTPUT

SELECT	@responseMessage as N'@responseMessage'

*/


-------------------------------------
-------------------------------------

-- stored procedure para criar um aluno
DROP PROC projeto.criarAluno
CREATE PROC projeto.criarAluno (@Data_Nasc DATE, @Telemovel VARCHAR(15), @Nome VARCHAR(50), @Sexo VARCHAR(20), @NIF INT, @Email VARCHAR(100), @Morada VARCHAR(200), @Mensalidade INT, @TURMA_Numero INT, @TURMA_ID INT)
AS	
	INSERT INTO projeto.Aluno (Data_Nasc, Telemovel, Nome, Sexo, NIF, Email, Morada, Mensalidade, TURMA_Numero, TURMA_ID) VALUES (@Data_Nasc, @Telemovel, @Nome, @Sexo, @NIF, @Email, @Morada, @Mensalidade, @TURMA_Numero, @TURMA_ID);
GO

-------------------------------------
-------------------------------------

--stored procedure para criar um professor
DROP PROC projeto.criarProfessor
CREATE PROC projeto.criarProfessor (@Data_Nasc DATE, @Telemovel VARCHAR(15), @Nome VARCHAR(50), @Sexo VARCHAR(20), @NIF INT, @Email VARCHAR(100), @Morada VARCHAR(200), @Salario INT, @DISCIPLINA_ID INT)
AS
	INSERT INTO projeto.Professor (Data_Nasc, Telemovel, Nome, Sexo, NIF, Email, Morada, Salario, DISCIPLINA_ID) VALUES (@Data_Nasc, @Telemovel, @Nome, @Sexo, @NIF, @Email, @Morada, @Salario, @DISCIPLINA_ID);
	
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



--stored procedure para adicionar intrumento ao aluno
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




-- procedure para dar update ao professor
DROP PROC projeto.updateProfessor
CREATE PROC projeto.updateProfessor (@PROFESSOR_Codigo INT, @Data_Nasc DATE, @Telemovel VARCHAR(15), @Nome VARCHAR(50), @Sexo VARCHAR(20), @NIF INT, @Email VARCHAR(100), @Morada VARCHAR(200), @DISCIPLINA_ID INT, @inst VARCHAR(30))
AS
	DECLARE @Salario INT	SET @Salario = projeto.getCountAlunosProf(@PROFESSOR_Codigo)


	UPDATE projeto.Professor 
	SET Data_Nasc = @Data_Nasc, Telemovel = @Telemovel, Nome = @Nome, Sexo = @Sexo, NIF = @NIF, Email = @Email, Morada = @Morada, Salario = @Salario
	WHERE PROFESSOR_Codigo = @PROFESSOR_Codigo

	EXEC projeto.addInstrumento @id=@PROFESSOR_Codigo, @instrumento=@inst
GO


-- procedure para dar update ao aluno
DROP PROC projeto.updateAluno
CREATE PROC projeto.updateAluno (@ALUNO_Codigo INT, @Data_Nasc DATE, @Telemovel VARCHAR(15), @Nome VARCHAR(50), @Sexo VARCHAR(20), @NIF INT, @Email VARCHAR(100), @Morada VARCHAR(200), @Mensalidade INT, @TURMA_Numero INT, @TURMA_ID VARCHAR(30), @inst VARCHAR(30))
AS
	

	UPDATE projeto.Aluno
	SET Data_Nasc = @Data_Nasc, Telemovel = @Telemovel, Nome = @Nome, Sexo = @Sexo, NIF = @NIF, Email = @Email, Morada = @Morada, Mensalidade = @Mensalidade, TURMA_Numero = @TURMA_Numero, DISCIPLINA_Nome = @TURMA_ID
	WHERE ALUNO_Codigo = @ALUNO_Codigo

	
	EXEC projeto.addInstrumento @id=@ALUNO_Codigo, @instrumento=@inst
GO




-- deleteAlunoE

DROP PROC projeto.deleteAlunoCREATE PROC projeto.deleteAluno (@id INT, @Instrumento VARCHAR(30))AS	DECLARE @num_ints INT	SET @num_ints =  (SELECT COUNT(ALUNO_Codigo) FROM projeto.Toca WHERE ALUNO_Codigo = @id) 	IF @num_ints > 1 	BEGIN		DELETE FROM projeto.Toca WHERE ALUNO_Codigo = @id AND INTRUMENTO_Nome = @instrumento		RETURN	END	IF @num_ints <= 1 	BEGIN 		DELETE FROM projeto.Aluno WHERE ALUNO_Codigo = @id		DELETE FROM projeto.Toca WHERE ALUNO_Codigo = @id	ENDGO-- criar eventoDROP PROC projeto.criarEvento CREATE PROC projeto.criarEvento (@id INT, @nome VARCHAR(30), @local VARCHAR(30), @data_inicio DATETIME, @data_fim DATETIME, @caract VARCHAR(30), @ano INT)AS	INSERT INTO projeto.Evento(EVENTO_Nome, Local, EVENTO_inicio, EVENTO_fim, Caracteristica, EVENTO_Ano, Aceite) VALUES(@nome, @Local, @Data_inicio, @Data_fim, @caract, @ano, 0)	INSERT INTO projeto.Request(Ano, PROFESSOR_Codigo, Aceitar, EVENTO_Nome_rq) VALUES(@ano, @id, 0, @nome)GO-- update eventoDROP PROC projeto.updateEventoCREATE PROC projeto.updateEvento (@id SMALLINT, @nome VARCHAR(30), @local VARCHAR(30), @data_inicio DATETIME, @data_fim DATETIME, @caract VARCHAR(30), @ano INT, @accept BIT)AS			UPDATE projeto.Evento 	SET EVENTO_Nome = @nome, Local= @local, EVENTO_inicio = @data_inicio, EVENTO_fim = @data_fim, Caracteristica = @caract, EVENTO_Ano = @ano, Aceite = @accept	WHERE EVENTO_Nome = @nome	IF @accept = 1	BEGIN		UPDATE projeto.Request		SET Ano = @ano, PROFESSOR_Codigo = @id, Aceitar = @accept, EVENTO_Nome_rq = @nome		WHERE EVENTO_Nome_rq = @nome	END	-- procedure criar turmaDROP PROC projeto.criarTurmaCREATE PROC projeto.criarTurma(@numero INT, @capacidade INT, @disciplina VARCHAR(30))AS	INSERT INTO projeto.Turma(Numero, Capacidade, DISCIPLINA_Nome) VALUES (@numero, @capacidade, @disciplina)	-- EXEC projeto.adicionarAlunoTurma @id = @id, @TURMA_Numero = @numero, @disciplinaID = @disciplina	select * from projeto.Turma--stored procedure para adicionar turma ao aluno
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

		INSERT INTO projeto.PertenceTurma (CODIGO_Aluno, TURMA_Numero) VALUES (@id, @TURMA_Numero)

	END
	
GO
SELECT * FROM projeto.PertenceTurma

--adicionar dire�ao
DROP PROC projeto.addProfessorDirecaoCREATE PROC projeto.addProfessorDirecao(@id SMALLINT, @cargo VARCHAR(30), @ano INT)AS		IF NOT EXISTS(		SELECT PROFESSOR_Codigo FROM projeto.Professor		WHERE PROFESSOR_Codigo = @id	)	BEGIN		PRINT 'PROFESSOR N�O EXISTE'		RETURN	END		IF EXISTS(		SELECT * FROM projeto.PertenceDirecao		WHERE Cargo = @cargo AND Ano = @ano	)	BEGIN		PRINT 'CARGO J� EST� PREENCHIDO!'		RETURN	END	IF EXISTS(		SELECT * FROM projeto.PertenceDirecao		WHERE CODIGO_Professor = @id AND Ano = @ano	)	BEGIN		PRINT 'PROFESSOR J� DESEMPENHA UM CARGO NA DIRECAO!'		RETURN 	END	INSERT INTO projeto.PertenceDirecao(CODIGO_Professor,  Ano, Cargo) VALUES(@id, @ano, @cargo)

-- atualizar salario
DROP PROC projeto.atualizarSalarioCREATE PROC projeto.atualizarSalarioAS	DECLARE @max_id SMALLINT	SET @max_id = (SELECT MAX(projeto.Professor.PROFESSOR_Codigo) FROM projeto.Professor)	DECLARE @current SMALLINT	SET @current = (SELECT MIN(projeto.Professor.PROFESSOR_Codigo) FROM projeto.Professor)	WHILE(@current <= @max_id) 	BEGIN		DECLARE @salario INT		SET @salario = projeto.getCountAlunosProf(@current)		UPDATE projeto.Professor		SET Salario = @salario		WHERE PROFESSOR_Codigo = @current		SET @current = @current + 1	END

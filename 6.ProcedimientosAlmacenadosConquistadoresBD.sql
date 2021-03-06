use ConquistadoresBD
GO
------------------------------------------- PROCEDIMIENTOS ALMACENADOS -------------------------------------------
--1.PROCEDIMIENTO ALMACENADO PARA AGREGAR PERSONAS (Se usa otros SP y prueba de triggers de manera m?s rapida)
create proc InsertarPersona(
	@Nombre nvarchar(25),
	@Apellidos nvarchar(50),
	@Sexo bit --0: HOMBRE , 1: MUJER
)as insert into persona (nombre,apellidos,sexo)
values(@Nombre,@Apellidos,@Sexo)
GO
--select * from persona
--exec InsertarPersona 'CACA','HUATE','1'

----PARA PROBAR EL SP 5
--INSERT INTO trabajador(trabajador_id,estatus,tipoEmp_id)
--VALUES(,0,1)
GO

--2.PROCEDIMIENTO ALMACENADO PARA MOSTRAR LOS INFORMACI?N DE EL INSTRUCTOR REQUERIDO
create proc InfoInstructor(
	@IDTrabajador int
)as IF @IDTrabajador in (select trabajador_id from trabajador where tipoEmp_id=5) --5 ES DE TIPO INSTRUCTOR
	begin
		select p.nombre+' '+p.apellidos as [Trabajador], t.estatus as [Estatus], e.nombre as[Tipo Empleado],es.nombre as [Especialidad] from persona p 
		inner join trabajador t on p.id=t.trabajador_id 
		inner join tipoEmpleado e on e.id= t.tipoEmp_id 
		inner join EspecialidadTrabajador ea on ea.trabajador_id=t.trabajador_id
		inner join especialidad es on es.id= ea.especialidad_id
		where p.id=@IDTrabajador
	end
ELSE
	print 'El ID ingresado no pertenece a ning?n instructor'

GO
--exec InfoInstructor '6'
GO
----------------------------INFORMACI?N DE TODOS LOS INSTRUCTORES PARA CALAR EL SP 2-------------------------------------
--select * from persona p inner join trabajador t on p.id=t.trabajador_id inner join tipoEmpleado e on e.id= t.tipoEmp_id inner join EspecialidadTrabajador ea on ea.trabajador_id=t.trabajador_id inner join especialidad es on es.id= ea.especialidad_id

--3.PROCEDIMIENTO ALMACENADO PARA DAR LOS CANTIDAD DE REQUISITOS PARA INVESTIRTE DE UNA CLASE EN PARTICULAR (Se usa en trigger)
create proc RequisitosInvestidura(
	@IDClase int
)as 
	declare @Num int
IF @IDClase in (select id from clase ) 
	begin
		select @Num=count(*)from(
		select a.id as [Actividad] from EspecialidadActividad ea 
		inner join actividad a on a.id = ea.actividad_id 
		inner join especialidad k on k.id = ea.especialidad_id 
		inner join clase c on c.id=k.clase_id
		where c.id=@IDClase
			union
		select  a.id as [Actividad] from clase cl
		inner join claseActividad ca on cl.id = ca.clase_id
		inner join actividad a on a.id = ca.actividad_id
		where cl.id=@IDClase) caca
			return @Num
	end
ELSE
	print 'El ID ingresado no es perteneciente a ninguna de las clases existentes'

GO
--exec RequisitosInvestidura '7'
GO

--4.PROCEDIMIENTO ALMACENADO PARA DAR LOS CANTIDAD DE ACTIVIDADES DE UNA ESPECIALIDAD (Se usa en trigger)
create proc ActividadEspecialidad(
	@IDClase int
)as 
	declare @Num int
IF @IDClase in (select id from clase ) 
	begin
		select @Num=count (a.id) from EspecialidadActividad ea 
		inner join actividad a on a.id = ea.actividad_id 
		inner join especialidad k on k.id = ea.especialidad_id 
		inner join clase c on c.id=k.clase_id
		where c.id=@IDClase
		return @Num
	end
ELSE
	print 'El ID ingresado no es perteneciente a ninguna de las clases existentes'

GO
--exec ActividadEspecialidad '1'
GO

--5.PROCEDIMIENTO ALMACENADO PARA LA CANTIDAD DE ACTIVIDADES QUE YA REALIZO UN NI?O DE UNA ESPECIALIDAD (Se usa en trigger)
create proc ActividadesRealizadasEspe(
	@IDClase int, 
	@IDNi?o int
)as 
	declare @Num int
IF @IDClase in (select id from clase ) and @IDNi?o  in (select nino_id from nino)
	begin
		select  @Num=count(*) from 
		(select a.id as [Actividad Especialidad] from EspecialidadActividad ea 
		inner join actividad a on a.id = ea.actividad_id 
		inner join especialidad k on k.id = ea.especialidad_id 
		inner join clase c on c.id=k.clase_id
		where c.id=@IDClase
			intersect
		select actividad_id from ninoactividad where nino_id=@IDNi?o) Done
		return @Num
	end
ELSE
	print 'Alguno de los ID ingresados no pertenece a la clase establecida'

GO
--exec ActividadesRealizadasEspe '5','205'
GO

--6.PROCEDIMIENTO ALMACENADO PARA MOSTRAR EL CONTROL DE LOS DATOS DE UN NI?O EN LAS REUNIONES A LAS QUE A ASISTIDO
create proc ControlNi?o(
	@IDNi?o int
)as IF @IDNi?o in (select nino_id from ReunionNino)
	begin
		select c.reunion_id as [Reunion] , p.nombre+' '+p.apellidos as  [Ni?o], r.Fecha as[Fecha Reunio], c.Cantidad as[Cantidad de cuota],
		a.asistencia as[Asistencia], a.puntualidad as[Puntualidad],a.tarea as[Tarea], pu.Nombre as[Pulcritud] from PagoCuota c 
		inner join nino n on n.nino_id = c.nino_id
		inner join persona p on p.id = n.nino_id 
		inner join Reunion r on r.ID = c.reunion_id
		inner join ReunionNino a on a.nino_id=n.nino_id
		inner join Pulcritud pu on pu.ID = a.pulcritud_id
		where p.id=@IDNi?o	
	end
ELSE
	begin
		IF @IDNi?o in (select nino_id from nino)
			print 'El ID del ni?o ingresado no ha asistido a ninguna reuni?n'
		ELSE
			print 'El ID ingresado no pertenece a ning?n ni?o'
	end
GO
--exec ControlNi?o'87'
GO

---------NI?OS QUE NO HAN ASISTIDO A NINGUNA REUNION
--select nino_id from nino except select nino_id from ReunionNino

--7.PROCEDIMIENTO ALMACENADO PARA ELIMINA UN EMPLEADO QUE YA NO ESTAN ACTIVOS
create proc EliminaEmpleado(
	@IDEmpleado int
)as IF @IDEmpleado in (select trabajador_id  from trabajador where estatus=0)
		delete trabajador where trabajador_id=@IDEmpleado
ELSE
	begin
		IF @IDEmpleado in (select trabajador_id  from trabajador)
			print 'El ID del empleado ingresado sigue activo'
		ELSE
			print 'El ID ingresado no pertenece a ning?n empleado'
	end

GO
--select trabajador_id  from trabajador 
--exec EliminaEmpleado '301'
--select trabajador_id  from trabajador 
GO

--------------------------------PROCEDIMIENTOS ALMACENADOS PARA LA APLICACI?N--------------------------------
--8.PROCEDIMIENTO ALMACENADO PARA ELIMINAR UN NI?O
create proc EliminaNi?o(
	@Nombre nvarchar(25),
	@Apellidos nvarchar(50)
)as 
	Declare @Ni?oID int
	select @Ni?oID=id from persona where nombre=@Nombre and apellidos=@Apellidos

	IF @Ni?oID in (select nino_id from nino)
	 begin
		delete from Ni?oEspecialidadCumplida where  Ni?oID=@Ni?oID
		delete from MasCumplido where  nino_id=@Ni?oID
		delete from Ni?o_Investidura where  nino_id=@Ni?oID
		delete from ninoClub where  nino_id=@Ni?oID
		delete from Padre_Nino where  IDNino=@Ni?oID
		delete from ninoClase where  nino_id=@Ni?oID
		delete from ninoUnidad where  nino_id=@Ni?oID
		delete from ReunionNino where  nino_id=@Ni?oID
		delete from PagoCuota where  nino_id=@Ni?oID
		delete from ninoActividad where  nino_id=@Ni?oID
		delete from alergiaNino where  nino_id=@Ni?oID
		delete from nino where  nino_id=@Ni?oID
		delete from persona where  id=@Ni?oID
	 end
	 ELSE
		print 'El ni?o que deseas eliminar no se encuentra registrado'

GO
--select  * from nino inner join persona on nino_id=id where nino_id=205
--exec EliminaNi?o 'Carolina','Lozano Benitez'
--select  * from nino inner join persona on nino_id=id where nino_id=205
GO

--9.PROCEDIMIENTO ALMACENADO PARA AGREGAR UN NI?O
create proc InsertarNi?o(
	--Datos ni?o
	@Nombre nvarchar(25),
	@Apellidos nvarchar(50),
	@Sexo bit, --0: HOMBRE , 1: MUJER
	@Estatura tinyint,
	@Peso tinyint,
	@FechaNacimiento date,

	--Datos tutor
	@NombreT nvarchar(25),
	@ApellidosT nvarchar(50),
	@SexoT bit, --0: HOMBRE , 1: MUJER
	@OcupacionID int

)as 
	Declare @Ni?oID int
	Declare @TutorID int

	--Para capturar los datos del ni?o
	exec InsertarPersona @Nombre,@Apellidos,@Sexo
	select @Ni?oID=id from persona where nombre=@Nombre and apellidos=@Apellidos and sexo=@Sexo

	--Para capturar los datos del tutor
	exec InsertarPersona @NombreT,@ApellidosT,@SexoT
	select @TutorID=id from persona where nombre=@NombreT and apellidos=@ApellidosT and sexo=@SexoT
	
	--Inserta primero al tutor
	insert into padre (padre_id,Ocupacion_ID) values(@TutorID,@OcupacionID)
	insert into nino (nino_id,estatura,peso,padre_id,fecha_nacimiento) values(@Ni?oID,@Estatura,@Peso,@TutorID,@FechaNacimiento)

GO
--select * from Ocupacion
--exec InsertarNi?o 'Carolina','Lozano Benitez','1','160','52','2004-05-11','Hectorin','Lozano','0','4'
--select * from nino inner join persona on nino_id=id where nombre like 'Carolina' and apellidos like 'Lozano Benitez'
GO

--10.PROCEDIMIENTO ALMACENADO PARA MODIFICAR LA ESTATURA DE UN NI?O
create proc ModificaNi?oEstatura(
	@Nombre nvarchar(25),
	@Apellidos nvarchar(50),
	@Estatura tinyint
)as 
	Declare @Ni?oID int
	select @Ni?oID=id from persona where nombre=@Nombre and apellidos=@Apellidos

	IF @Ni?oID in (select nino_id from nino)
		update  nino  set estatura=@Estatura where nino_id=@Ni?oID
	ELSE 
		print 'El ni?o ingresado no se encuentra registrado'

GO
--exec ModificaNi?oEstatura 'Carolina','Lozano Benitez','159'
--select  * from nino inner join persona on nino_id=id where nino_id=205
GO

--11.PROCEDIMIENTO ALMACENADO PARA MODIFICAR EL PESO DE UN NI?O
create proc ModificaNi?oPeso(
	@Nombre nvarchar(25),
	@Apellidos nvarchar(50),
	@Peso tinyint
)as 
	Declare @Ni?oID int

	select @Ni?oID=id from persona where nombre=@Nombre and apellidos=@Apellidos

	IF @Ni?oID in (select nino_id from nino)
		update  nino  set peso=@Peso where nino_id=@Ni?oID
	ELSE 
		print 'El ni?o ingresado no se encuentra registrado'

GO
--exec ModificaNi?oPeso 'Carolina','Lozano Benitez','50'
--select  * from nino inner join persona on nino_id=id where nino_id=205
GO

--12.PROCEDIMIENTO ALMACENADO PARA MODIFICAR EL PESO DE UN NI?O
create proc ModificaNi?oFechaNacimiento(
	@Nombre nvarchar(25),
	@Apellidos nvarchar(50),
	@FechaNacimiento date
)as 
	Declare @Ni?oID int
	select @Ni?oID=id from persona where nombre=@Nombre and apellidos=@Apellidos
	
	IF @Ni?oID in (select nino_id from nino)
		update  nino  set fecha_nacimiento=@FechaNacimiento where nino_id=@Ni?oID
	ELSE 
		print 'El ni?o ingresado no se encuentra registrado'

GO
--exec ModificaNi?oFechaNacimiento 'Carolina','Lozano Benitez','2005-12-01'
--select  * from nino inner join persona on nino_id=id where nino_id=205
GO


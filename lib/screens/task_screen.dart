StreamBuilder(
  stream: service.getTasks(),
  builder: (context, snapshot) {

    if(!snapshot.hasData){
      return CircularProgressIndicator();
    }

    final docs =
      snapshot.data!.docs;

    return ListView.builder(

      itemCount: docs.length,

      itemBuilder: (context,index){

        final task =
            docs[index];

        return ListTile(

          title:
              Text(task['titulo']),

          subtitle:
              Text(task['disciplina']),

          trailing:
              IconButton(

            icon:
                Icon(Icons.delete),

            onPressed: () {

              service.deleteTask(
                  task.id);
            },
          ),
        );
      },
    );
  },
)
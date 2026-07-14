/// Versículo del día.
///
/// Contenido local y determinista: el mismo día siempre da el mismo versículo,
/// sin red y sin IA. Es el mínimo honesto mientras no exista `daily_verse_plan`
/// en la base (Sprint 5): un versículo fijo para siempre no es una experiencia
/// diaria, es un adorno.
class Versiculo {
  const Versiculo(this.texto, this.cita);
  final String texto;
  final String cita;
}

const List<Versiculo> _versiculos = [
  Versiculo(
    'Todo lo puedo en Cristo que me fortalece.',
    'Filipenses 4:13',
  ),
  Versiculo(
    'Esfuérzate y sé valiente; no temas ni desmayes, porque el Señor tu Dios '
        'estará contigo dondequiera que vayas.',
    'Josué 1:9',
  ),
  Versiculo(
    'Encomienda al Señor tu camino, confía en él, y él hará.',
    'Salmos 37:5',
  ),
  Versiculo(
    'Bástate mi gracia; porque mi poder se perfecciona en la debilidad.',
    '2 Corintios 12:9',
  ),
  Versiculo(
    'El Señor es mi pastor; nada me faltará.',
    'Salmos 23:1',
  ),
  Versiculo(
    'No se turbe vuestro corazón; creéis en Dios, creed también en mí.',
    'Juan 14:1',
  ),
  Versiculo(
    'Los que esperan en el Señor tendrán nuevas fuerzas; levantarán alas como '
        'las águilas; correrán y no se cansarán.',
    'Isaías 40:31',
  ),
  Versiculo(
    'Echad toda vuestra ansiedad sobre él, porque él tiene cuidado de vosotros.',
    '1 Pedro 5:7',
  ),
  Versiculo(
    'Lámpara es a mis pies tu palabra, y lumbrera a mi camino.',
    'Salmos 119:105',
  ),
  Versiculo(
    'Todo tiene su tiempo, y todo lo que se quiere debajo del cielo tiene su hora.',
    'Eclesiastés 3:1',
  ),
  Versiculo(
    'Fíate del Señor de todo tu corazón, y no te apoyes en tu propia prudencia.',
    'Proverbios 3:5',
  ),
  Versiculo(
    'Mi alma está abatida; vivifícame según tu palabra.',
    'Salmos 119:25',
  ),
  Versiculo(
    'Por nada estéis afanosos, sino sean conocidas vuestras peticiones delante '
        'de Dios en toda oración y ruego, con acción de gracias.',
    'Filipenses 4:6',
  ),
  Versiculo(
    'Nuevas son cada mañana sus misericordias; grande es su fidelidad.',
    'Lamentaciones 3:23',
  ),
  Versiculo(
    'Venid a mí todos los que estáis trabajados y cargados, y yo os haré descansar.',
    'Mateo 11:28',
  ),
  Versiculo(
    'El Señor peleará por vosotros, y vosotros estaréis tranquilos.',
    'Éxodo 14:14',
  ),
  Versiculo(
    'Sabemos que a los que aman a Dios, todas las cosas les ayudan a bien.',
    'Romanos 8:28',
  ),
  Versiculo(
    'Este es el día que hizo el Señor; nos gozaremos y alegraremos en él.',
    'Salmos 118:24',
  ),
  Versiculo(
    'Estad quietos, y conoced que yo soy Dios.',
    'Salmos 46:10',
  ),
  Versiculo(
    'Porque yo sé los pensamientos que tengo acerca de vosotros: pensamientos '
        'de paz, y no de mal, para daros el fin que esperáis.',
    'Jeremías 29:11',
  ),
  Versiculo(
    'El que comenzó en vosotros la buena obra, la perfeccionará.',
    'Filipenses 1:6',
  ),
  Versiculo(
    'Buscad primeramente el reino de Dios y su justicia, y todas estas cosas '
        'os serán añadidas.',
    'Mateo 6:33',
  ),
  Versiculo(
    'No temas, porque yo estoy contigo; no desmayes, porque yo soy tu Dios que '
        'te esfuerzo.',
    'Isaías 41:10',
  ),
  Versiculo(
    'Mejor es el fin del negocio que su principio; mejor es el sufrido de '
        'espíritu que el altivo de espíritu.',
    'Eclesiastés 7:8',
  ),
  Versiculo(
    'Alaba, alma mía, al Señor, y no olvides ninguno de sus beneficios.',
    'Salmos 103:2',
  ),
  Versiculo(
    'La palabra de Dios es viva y eficaz.',
    'Hebreos 4:12',
  ),
  Versiculo(
    'El corazón del hombre traza su camino, pero el Señor endereza sus pasos.',
    'Proverbios 16:9',
  ),
  Versiculo(
    'Basta a cada día su propio mal.',
    'Mateo 6:34',
  ),
  Versiculo(
    'En paz me acostaré, y asimismo dormiré; porque solo tú, Señor, me haces '
        'vivir confiado.',
    'Salmos 4:8',
  ),
  Versiculo(
    'Hasta aquí nos ayudó el Señor.',
    '1 Samuel 7:12',
  ),
  Versiculo(
    'El gozo del Señor es vuestra fuerza.',
    'Nehemías 8:10',
  ),
];

/// Versículo correspondiente a [dia]. Determinista: recorre la lista completa
/// antes de repetir, y el mismo día siempre devuelve el mismo versículo.
Versiculo versiculoDelDia(DateTime dia) {
  final inicioAno = DateTime(dia.year, 1, 1);
  final diaDelAno = dia.difference(inicioAno).inDays;
  return _versiculos[diaDelAno % _versiculos.length];
}

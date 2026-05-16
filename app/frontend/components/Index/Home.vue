<template>
    <h1>Bine ați venit în baza de date a orientării sportive</h1>
    <table class="table table-bordered ">
        <thead>
            <tr class="table-primary">
                <th scope="col">Sportivi</th>
                <th scope="col">Cluburi</th>
                <th scope="col">Rezultate</th>
                <th scope="col">Competiții</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><a href="/runners">{{countData.runners_count}}</a></td>
                <td><a href="/clubs">{{countData.clubs_count}}</a></td>
                <td><a href="/results">{{countData.results_count}}</a></td>
                <td><a href="/competitions">{{countData.competitions_count}}</a></td>
            </tr>
        </tbody>
    </table>
    <h1> Ultimele 10 Competiții</h1>
        <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th>ID</th>
                <th>Data</th>
                <th>Nume</th>
                <th>Oraș</th>
                <th>Țara</th>
                <th>Tipul Distanței</th>
                <th>WRE ID</th>
                <th>ECN</th>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in competitionData" :key="element.id">
                <td><a :href="`competitions/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`competitions/${element.id}`">{{ element.date }}</a></td>
                <td><a :href="`competitions/${element.id}`">{{ element.competition_name }}</a></td>
                <td>{{ element.location }}</td>
                <td>{{ element.country }}</td>
                <td>{{ element.distance_type }}</td>
                <td>{{ element.wre_id }}</td>
                <td :class="element.ecn ? 'bg-true' : 'bg-false'">
                    {{ element.ecn ? "Da" : "Nu" }}
                </td>
                <td>
                    <a class="btn btn-sm btn-warning" :href="`competitions/${element.id}`">
                        Arată
                    </a>
                </td>
                <td>
                    <button class="btn btn-sm btn-success" @click="editElement(element)">
                        Editează
                    </button>
                </td>
                <td>
                    <button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">
                        Șterge
                    </button>
                </td>
            </tr>
        </tbody>
    </table>

</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from '@/axios'

const competitionData = ref([])
const countData = ref([])

onMounted(() => {
    getCountData();
    getCompetitionData();
})

async function getCountData() {
    const res = await axios.get('/home/index.json');
    countData.value = res.data;
}

async function getCompetitionData() {
    const params = {
        "sorting[sort_by]": "date",
        "sorting[direction]": "desc",
        "limit": 10
    }

    const res = await axios.get('/competitions.json', { params: params });
    competitionData.value = res.data;
}
</script>
<style scoped>
    .bg-true {
      background-color: #d4edda;
    }

    .bg-false {
      background-color: #f8d7da;
    }
</style>

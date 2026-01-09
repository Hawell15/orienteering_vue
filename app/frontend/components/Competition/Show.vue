<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1> {{competition.competition_name}} </h1>
        <hr class="my-4">
        <p><strong>Data: </strong>{{competition.date}}</p>
        <p><strong>Tipul Distanței: </strong>{{competition.distance_type}}</p>
        <p><strong>ECN: </strong>{{competition.ecn ? "Da" : "Nu"}}</p>
        <p v-if="competition.wre_id"><strong>WRE ID: </strong><a :href="`http://ranking.orienteering.sport/ResultsView?event=${competition.wre_id}`">{{competition.wre_id}}</a></p>
        <hr class="my-4">
        <p><strong>Orașul: </strong>{{competition.location}}</p>
        <p><strong>Țara: </strong>{{competition.country}}</p>
        <ul class="nav nav-pills mb-3">
            <li class="nav-item" v-for="g in groups" :key="g.id">
                <button class="nav-link" :class="{ active: activeGroup?.id === g.id }" @click="selectGroup(g)">
                    {{ g.group_name }}
                </button>
            </li>
        </ul>
        <table v-if="activeGroup" class="table table-striped table-bordered table-hover">
            <thead class="table-primary">
                <tr>
                    <td @click="orderResultTable('place')">Locul</td>
                    <td @click="orderResultTable('full_name')">Sportiv</td>
                    <td @click="orderResultTable('yob')">Anul Nașterii</td>
                    <td @click="orderResultTable('club_name')">Club</td>
                    <td @click="orderResultTable('runner_category_name')">Categoria actuala</td>
                    <td @click="orderResultTable('time')">Timpul</td>
                    <td @click="orderResultTable('result_category_name')">Categoria Indeplinita</td>
                    <td @click="orderResultTable('status')">Indeplinire</td>
                    <td @click="orderResultTable('wre_points')">WRE Puncte</td>
                    <td @click="orderResultTable('ecn_points')">ECN Puncte</td>
                    <th colspan="3">Actiuni</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="element in activeGroup.results" :key="element.id">
                    <td>{{element.place}}</td>
                    <td><a :href="`/runners/${element.runner_id}`">{{element.full_name}}</a></td>
                    <td>{{element.yob}}</td>
                    <td><a :href="`/clubs/${element.club_id}`">{{element.club_name}}</a></td>
                    <td><a :href="`/categories/${element.runner_category_id}`">{{element.runner_category_name}}</a></td>
                    <td>{{formatResultTime(element.time)}}</td>
                    <td><a :href="`/categories/${element.result_category_id}`">{{element.result_category_name}}</a></td>
                    <td :class="element.status">{{formatStatus(element.status)}}</td>
                    <td>{{element.wre_points}}</td>
                    <td>{{element.ecn_points}}</td>
                    <td>
                        <a class="btn btn-sm btn-warning" :href="`/results/${element.id}`">
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
        <div class="half-width-table">
            <table class="table table-striped table-bordered table-hover">
                <thead class="table-warning">
                    <tr>
                        <th scope="col"> Categoria
                        </th>
                        <th> Procente
                        </th>
                        <th> Timpul
                        </th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>
                        </td>
                        <td>
                        </td>
                        <td>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div>Rang: {{activeGroup?.group_rang }} </div>
        <div>Clasa: {{formatGroupClasa(activeGroup?.group_clasa)}} </div>
    </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const competition = ref({})
const competitionId = ref("")

const groups = ref([])
const activeGroup = ref(null)

onMounted(() => {
    competitionId.value = window.location.pathname.split('/').pop();
    getData();
    getResults();
})

async function getData() {
    const res = await axios.get(`/competitions/${competitionId.value}.json`)
    competition.value = res.data;
}

async function getResults() {
    const params = {
        "competition": competitionId.value,
        "sorting[sort_by]": "place",
        "sorting[direction]": "asc",
    }
    const res = await axios.get('/results.json', { params: params })
    groups.value = Object.values(convertResultsFormat(res.data));

    selectGroupFromHash();
}

function convertResultsFormat(results) {
    const groupsMap = {};

    results.forEach(r => {
        if (!groupsMap[r.group_id]) {
            groupsMap[r.group_id] = {
                id: r.group_id,
                group_name: r.group_name,
                group_rang: r.group_rang,
                results: []
            }
        }
        groupsMap[r.group_id].results.push(r)
    })
    return groupsMap;
}

function selectGroup(group) {
    activeGroup.value = group
    window.location.hash = group.group_name
}

function selectGroupFromHash() {
    const hash = window.location.hash.replace("#", "")

    if (!hash) {
        activeGroup.value = groups.value[0]
        return
    }

    const found = groups.value.find(g => g.group_name === hash)

    activeGroup.value = found || groups.value[0]
}

function formatResultTime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    return (
        String(h).padStart(2, '0') + ':' +
        String(m).padStart(2, '0') + ':' +
        String(s).padStart(2, '0')
    );
}

function formatStatus(status) {
    const map = { confirmed: "Îndeplinit", pending: "În așteptare", unconfirmed: "Neconfirmat" }
    return map[status]
}

function formatGroupClasa(clasa) {
    const map = {
        "2": "MSRM",
        "3": "CMSRM",
        "4": "I",
        "5": "II",
        "7": "I j",
        "10": "f/c"
    }
    return map[clasa]
}
</script>
<style scoped>
.confirmed {
    background-color: #d4edda;
}

.pending {
    background-color: #ADD8E6;
}

.unconfirmed {
    background-color: #f8d7da;
}
</style>

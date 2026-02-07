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
        <ResultsTable :elements="activeGroup.results" @order="orderResultTable"></ResultsTable>
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
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editElement(competition)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteCompetition(competition.id)">Sterge</button>
        <button class="btn btn-secondary btn-sm" @click="goBack()">Înapoi</button>
    </p>
    <Modal ref="modal" :competition="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'
import ResultsTable from '../Result/Table.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[ name="csrf-token"]').getAttribute('content')

const competition = ref({})
const competitionId = ref("")
const modalElement = ref({})
const modal = ref(null)

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

function editElement(competition) {
    modalElement.value = { ...competition }
    modal.value.show()
}

function updateElement(competitionData, done) {
    axios.patch(`/competitions/${competitionData.id}.json`, { competition: competitionData }).then(res => {
        competition.value = res.data
        done()
    })
}

function deleteCompetition(id) {
    if (confirm('Esti sigur ca vrei sa stergi această competiție?')) {
        axios.delete(`/competitions/${id}`).then(() => {
            if (document.referrer) {
                window.location = document.referrer;
            } else {
                window.location = "/competitions";
            }
        })
    }
}

function goBack() {
    if (document.referrer) {
        window.location = document.referrer;
    } else {
        window.location = "/competitions";
    }
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
